#!/usr/bin/env bash
#
# security-audit.sh - vulnerability / supply-chain audit for RF Swift Nix tools.
#
# RF Swift's environments bundle a large third-party tool surface. This script
# audits that surface for known vulnerabilities from several angles, so a CVE in
# any bundled component (a C library deep in a closure, a vendored Python/Go
# module, ...) is surfaced rather than shipped silently:
#
#   1. vulnix      - Nix-native CVE scan. Reads each derivation in the realised
#                    closure and matches its name/version against the NVD feed
#                    (CPE). The authoritative "which nixpkgs packages in this
#                    environment have known CVEs" check.
#   2. syft        - Software Bill of Materials (CycloneDX). Catalogs the concrete
#                    components inside the closure (binaries, Python dists, Go
#                    modules, ...) and is kept as a supply-chain artifact.
#   3. grype       - Scans that SBOM for CVEs (NVD + GitHub advisories), a second
#                    independent source that also covers language ecosystems.
#   4. osv-scanner - Scans the SBOM against OSV (GHSA and other supply-chain
#                    advisory databases), catching ecosystem advisories that are
#                    not (yet) CPE-mapped in NVD.
#
# Beyond CVEs, the report also covers integrity, supply-chain and configuration
# health so problems other than "a component has a CVE" are surfaced too:
#
#   5. integrity   - `nix store verify` on each closure. A content-hash mismatch
#                    means a store path is CORRUPTED (or was tampered with).
#   6. provenance  - `nix store verify --sigs` reports paths with no trusted
#                    signature (locally built vs. cache-supplied), a supply-chain
#                    signal about what is and is not attested by a cache.
#   7. config      - repository-level hygiene run once: every flake.lock input is
#                    pinned by narHash; no placeholder/unpinned source hashes are
#                    left in pkgs/ (an unpinned fetch is a supply-chain hole); and
#                    any allowInsecure / permittedInsecurePackages escape hatches
#                    are flagged for review. Per target, evaluation warnings
#                    (deprecations, insecure markers) are captured too.
#
# All scanners are fetched from THIS flake's pinned nixpkgs (`--inputs-from .`),
# so the audit tooling is reproducible and needs nothing pre-installed but Nix.
# The scanners fetch their vulnerability databases at run time, so the audit
# needs network access (unlike the build/eval gates, which are offline).
#
# Design: the audit is FAULT-TOLERANT and REPORT-FIRST. Every scanner runs
# independently; a scanner that errors, or a target that will not realise, is
# recorded and the audit keeps going so you always get the complete picture in
# one pass. The script exits 0 (success = "the audit ran") regardless of what it
# finds, UNLESS you pass --fail-on to turn it into a gate - and even then it only
# decides the exit code after every scan has completed.
#
# Usage:
#   scripts/security-audit.sh [--all | --env NAME ...] [--pkg ATTR ...] [--image REF ...]
#                             [--out DIR] [--format LIST] [--fail-on LEVEL] [--no-build]
#
#   --all            audit every environment in catalog.json
#   --env NAME       audit one environment closure (repeatable)
#   --pkg ATTR       audit one packages.<system>.<attr>, e.g. pkg-unblob (repeatable)
#   --image REF      audit a container image (docker/podman OCI ref), e.g.
#                    penthertz/rfswift:sdr_full - scanned natively with syft,
#                    grype and trivy (repeatable). This is the container-engine
#                    counterpart of --env, so any RF Swift engine can be audited.
#   --out DIR        write reports here (default: ./security-report)
#   --format LIST    comma-separated output formats (default: stdout,txt):
#                      stdout - print the coloured/emoji report to the terminal
#                      txt    - security-report/summary.txt (always written)
#                      json   - security-report/report.json (machine-readable)
#                      html   - security-report/report.html
#                      pdf    - security-report/report.pdf (rendered from html)
#                    'all' selects stdout,txt,json,html,pdf.
#   --fail-on LEVEL  after all scans finish, exit non-zero if any finding is
#                    >= LEVEL (none|low|medium|high|critical; default: none)
#   --no-build       only scan targets already in the store; do not realise them
#   -h, --help       show this help
#
# With no target flag it audits a small default environment (sdr_light).
#
# Examples:
#   scripts/security-audit.sh --env wifi --env telecom --out /tmp/report
#   scripts/security-audit.sh --all                          # report everything
#   scripts/security-audit.sh --all --format all             # every output format
#   scripts/security-audit.sh --all --fail-on critical       # CI gate on criticals
#   scripts/security-audit.sh --pkg pkg-unblob --format json,html

# NOTE: deliberately NOT `set -e`. A vulnerability audit must complete every scan
# even when individual tools error or find problems; we handle errors explicitly
# and keep going. `pipefail`/`nounset` stay on for correctness.
set -uo pipefail

# The directory reports are written to defaults to the INVOCATION directory, not
# the flake dir (which may be a read-only /nix/store path when this runs as the
# flake `audit` app). RFSWIFT_AUDIT_FLAKE lets the app point the audit at the
# flake source in the store; standalone it is the repo root next to this script.
invoke_dir="$PWD"
repo="${RFSWIFT_AUDIT_FLAKE:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
cd "$repo" || { echo "error: cannot cd to flake dir $repo" >&2; exit 2; }

nix=(nix --extra-experimental-features "nix-command flakes")
system=${RFSWIFT_TEST_SYSTEM:-$("${nix[@]}" eval --raw --impure --expr builtins.currentSystem 2>/dev/null || echo x86_64-linux)}

# -------- argument parsing --------------------------------------------------
declare -a envs=() pkgs=() images=()
out_dir="$invoke_dir/security-report"
fail_on="none"
do_build=1
formats="stdout,txt"

die() { echo "error: $*" >&2; exit 2; }

while [[ $# -gt 0 ]]; do
  case "$1" in
    --all)      mapfile -t envs < <(jq -r '.environments[].name' catalog.json); shift ;;
    --env)      [[ -n "${2:-}" ]] || die "--env needs a NAME"; envs+=("$2"); shift 2 ;;
    --pkg)      [[ -n "${2:-}" ]] || die "--pkg needs an ATTR"; pkgs+=("$2"); shift 2 ;;
    --image)    [[ -n "${2:-}" ]] || die "--image needs a REF"; images+=("$2"); shift 2 ;;
    --out)      [[ -n "${2:-}" ]] || die "--out needs a DIR"; out_dir="$2"; shift 2 ;;
    --fail-on)  [[ -n "${2:-}" ]] || die "--fail-on needs a LEVEL"; fail_on="$2"; shift 2 ;;
    --format)   [[ -n "${2:-}" ]] || die "--format needs a LIST"; formats="$2"; shift 2 ;;
    --no-build) do_build=0; shift ;;
    -h|--help)  awk 'NR>=3{ if(/^set -uo pipefail/)exit; sub(/^# ?/,""); print }' "${BASH_SOURCE[0]}"; exit 0 ;;
    *)          die "unknown argument: $1" ;;
  esac
done

case "$fail_on" in none|low|medium|high|critical) ;; *) die "--fail-on must be none|low|medium|high|critical" ;; esac
[[ "$formats" == all ]] && formats="stdout,txt,json,html,pdf"
want_fmt() { [[ ",${formats}," == *",$1,"* ]]; }
for f in ${formats//,/ }; do
  case "$f" in stdout|txt|json|html|pdf) ;; *) die "--format items must be stdout,txt,json,html,pdf (or 'all')" ;; esac
done

if [[ ${#envs[@]} -eq 0 && ${#pkgs[@]} -eq 0 && ${#images[@]} -eq 0 ]]; then
  envs=(sdr_light)
  echo "No target given; auditing default environment '${envs[0]}'. Use --all, --env/--pkg, or --image to widen."
fi

mkdir -p "$out_dir"

# Severity ranking, and the worst severity seen across the whole run.
sev_rank() { case "${1,,}" in critical) echo 4 ;; high) echo 3 ;; medium|moderate) echo 2 ;; low) echo 1 ;; *) echo 0 ;; esac; }
worst_rank=0
note_worst() { local r; r=$(sev_rank "$1"); if (( r > worst_rank )); then worst_rank=$r; fi; }
rank_name() { case "$1" in 4) echo critical ;; 3) echo high ;; 2) echo medium ;; 1) echo low ;; *) echo none ;; esac; }

# summary.txt is the canonical text report and the working log; it is always
# written into the output directory. The `stdout` format toggles the terminal
# echo; `txt` marks summary.txt as a requested deliverable (it is produced either
# way). json/html/pdf are rendered from structured data after the scans.
summary="$out_dir/summary.txt"
: > "$summary"
to_term=0; want_fmt stdout && to_term=1
log() { printf '%s\n' "$*" >> "$summary"; [[ $to_term -eq 1 ]] && printf '%s\n' "$*" || true; }

# Status line with an emoji (and ANSI colour on a real terminal). The file copy
# stays plain-with-emoji so it renders in editors and the GitHub step summary;
# colour is added only for the interactive terminal echo.
use_color=0; [[ -t 1 && $to_term -eq 1 ]] && use_color=1
sline() {
  local st="$1"; shift
  local ico clr
  case "$st" in
    ok)   ico="✅"; clr=$'\e[32m' ;;
    warn) ico="⚠️ "; clr=$'\e[33m' ;;
    err)  ico="❌"; clr=$'\e[31m' ;;
    *)    ico="ℹ️ "; clr=$'\e[36m' ;;
  esac
  printf '  %s %s\n' "$ico" "$*" >> "$summary"
  if [[ $to_term -ne 1 ]]; then return 0; fi
  if [[ $use_color -eq 1 ]]; then printf '  %b%s %s\e[0m\n' "$clr" "$ico" "$*"
  else printf '  %s %s\n' "$ico" "$*"; fi
}
issues=()   # human-readable "potential issue" lines collected across the run
declare -a target_json=()   # one structured JSON object per scanned target
# repository-level results (filled by repo_checks)
repo_locked=true; repo_unpinned=""; repo_placeholder=0; repo_insecure=0

# -------- realise a target to a store path ----------------------------------
# Prints the store path on success; empty on failure. Never aborts.
realise() {
  local attr="$1" path=""
  if [[ $do_build -eq 1 ]]; then
    path=$("${nix[@]}" build ".#packages.${system}.\"${attr}\"" --no-link --print-out-paths 2>/dev/null) || path=""
  else
    path=$("${nix[@]}" eval --raw ".#packages.${system}.\"${attr}\"" 2>/dev/null) || path=""
    [[ -n "$path" && -e "$path" ]] || path=""
  fi
  printf '%s' "$path"
}

run_tool() { "${nix[@]}" run --inputs-from . "nixpkgs#$1" -- "${@:2}"; }

# -------- scan one realised store path ---------------------------------------
# Append a structured result object for the current target to target_json.
emit_target_json() {
  target_json+=("$(jq -n \
    --arg label "$1" --arg closure "$2" \
    --argjson vulnix "$3" --argjson components "$4" \
    --argjson gc "$5" --argjson gh "$6" --argjson gm "$7" --argjson gl "$8" \
    --argjson osv "$9" --arg integrity "${10}" \
    --argjson unsigned "${11}" --argjson warns "${12}" --argjson vulnerabilities "${13}" \
    '{label:$label, closure:$closure,
      vulnix_cves:$vulnix, sbom_components:$components,
      grype:{critical:$gc, high:$gh, medium:$gm, low:$gl},
      osv_advisories:$osv, integrity:$integrity,
      unsigned_paths:$unsigned, eval_warnings:$warns,
      vulnerabilities:$vulnerabilities}')")
}

scan_target() {
  local label="$1" attr="$2" path="$3"
  local safe=${label//[^A-Za-z0-9._-]/_}
  # structured captures (-1 == the scanner errored / did not produce output)
  local t_vulnix=0 t_vulnix_findings="[]" t_components=0 t_gc=0 t_gh=0 t_gm=0 t_gl=0 t_osv=0 t_integrity="ok" t_unsigned=0 t_warns=0
  log ""
  log "=== ${label} ==="
  log "  closure: ${path}"

  # 1) vulnix: Nix-native closure CVE scan. Exit code is non-zero when it finds
  # vulnerabilities (1) or has nothing to report in the way we expect; we key off
  # the JSON it writes, not the exit code, so findings and tool errors are
  # distinguished cleanly.
  local vjson="$out_dir/vulnix-${safe}.json" vlog="$out_dir/vulnix-${safe}.log"
  if run_tool vulnix --json "$path" >"$vjson" 2>"$vlog"; then :; fi
  if [[ -s "$vjson" ]] && jq -e . "$vjson" >/dev/null 2>&1; then
    local vn runtime_names
    vn=$(jq '[.[].affected_by[]?] | length' "$vjson" 2>/dev/null || echo 0)
    runtime_names=$("${nix[@]}" path-info --recursive --json "$path" 2>/dev/null |
      jq '[keys[] | split("/")[-1] | sub("^[^-]+-"; "")]' 2>/dev/null || echo '[]')
    t_vulnix_findings=$(jq --argjson runtime "$runtime_names" '[.[] as $pkg | $pkg.affected_by[]? as $cve |
      ($pkg.cvssv3_basescore[$cve] // null) as $score |
      {id:$cve, cve:$cve, scanner:"vulnix", package:($pkg.pname // $pkg.name),
       installed_version:($pkg.version // ""), derivation:($pkg.derivation // ""),
       runtime_closure:(($runtime | index($pkg.name)) != null),
       scope:(if (($runtime | index($pkg.name)) != null) then "runtime" else "build-time" end),
       disposition:"scanner-match-unvalidated",
       cvss_score:$score,
       severity:(if $score == null then "unknown" elif $score >= 9 then "critical"
                 elif $score >= 7 then "high" elif $score >= 4 then "medium" else "low" end),
       title:($pkg.description[$cve] // "Known vulnerability reported by vulnix")}]' "$vjson" 2>/dev/null || echo '[]')
    if [[ "$vn" =~ ^[0-9]+$ && "$vn" -gt 0 ]]; then
      t_vulnix=$vn
      sline warn "vulnix:      ${vn} CVE match(es) -> ${vjson}"
      note_worst high
      issues+=("${label}: vulnix reports ${vn} CVE match(es)")
    else
      sline ok "vulnix:      no known CVEs in the closure"
    fi
  else
    t_vulnix=-1
    sline err "vulnix:      SCAN ERROR (see ${vlog})"
    issues+=("${label}: vulnix did not complete (tool/database error)")
  fi

  # 2) syft SBOM (CycloneDX) - supply-chain artifact and grype/osv input.
  local sbom="$out_dir/sbom-${safe}.cdx.json" slog="$out_dir/syft-${safe}.log"
  run_tool syft scan "dir:${path}" -o "cyclonedx-json=${sbom}" -q >/dev/null 2>"$slog" || true
  if [[ -s "$sbom" ]]; then
    t_components=$(jq '.components|length' "$sbom" 2>/dev/null || echo 0)
    sline ok "syft:        SBOM -> ${sbom} (${t_components} components)"
  else
    t_components=-1; t_gc=-1; t_gh=-1; t_gm=-1; t_gl=-1; t_osv=-1
    sline err "syft:        SBOM generation failed (see ${slog}); grype/osv skipped for this target"
    issues+=("${label}: syft SBOM failed - grype/osv could not run")
  fi

  if [[ -s "$sbom" ]]; then
    # 3) grype CVE scan of the SBOM (NVD + GHSA), with SARIF for code scanning.
    local gjson="$out_dir/grype-${safe}.json" gsarif="$out_dir/grype-${safe}.sarif" glog="$out_dir/grype-${safe}.log"
    run_tool grype "sbom:${sbom}" -o json="$gjson" -o sarif="$gsarif" -q >/dev/null 2>"$glog" || true
    if [[ -s "$gjson" ]] && jq -e . "$gjson" >/dev/null 2>&1; then
      local gsev
      gsev() { jq --arg s "$1" '[.matches[]|select((.vulnerability.severity//""|ascii_downcase)==$s)]|length' "$gjson" 2>/dev/null || echo 0; }
      t_gc=$(gsev critical); t_gh=$(gsev high); t_gm=$(gsev medium); t_gl=$(gsev low)
      local counts
      counts=$(jq -r '[.matches[].vulnerability.severity] | group_by(ascii_downcase) | map("\(.[0])=\(length)") | join(" ")' "$gjson" 2>/dev/null || echo "")
      if [[ -z "$counts" ]]; then
        sline ok "grype:       no findings -> ${gjson}"
      else
        sline warn "grype:       ${counts} -> ${gjson}"
      fi
      while IFS= read -r gsev; do
        [[ -z "$gsev" ]] && continue
        note_worst "$gsev"
        if [[ "$(sev_rank "$gsev")" -ge 3 ]]; then issues+=("${label}: grype ${gsev} finding(s) present"); fi
      done < <(jq -r '.matches[].vulnerability.severity' "$gjson" 2>/dev/null | sort -u)
    else
      t_gc=-1; t_gh=-1; t_gm=-1; t_gl=-1
      sline err "grype:       SCAN ERROR (see ${glog})"
      issues+=("${label}: grype did not complete")
    fi

    # 4) osv-scanner against the SBOM (OSV / GHSA supply-chain advisories).
    local ojson="$out_dir/osv-${safe}.json" olog="$out_dir/osv-${safe}.log"
    run_tool osv-scanner --format json --sbom="$sbom" >"$ojson" 2>"$olog" || true
    if [[ -s "$ojson" ]] && jq -e . "$ojson" >/dev/null 2>&1; then
      local on
      on=$(jq '[.results[]?.packages[]?.vulnerabilities[]?] | length' "$ojson" 2>/dev/null || echo 0)
      t_osv=$on
      if [[ "$on" =~ ^[0-9]+$ && "$on" -gt 0 ]]; then
        sline warn "osv-scanner: ${on} advisory match(es) -> ${ojson}"
        note_worst high
        issues+=("${label}: osv-scanner reports ${on} advisory match(es)")
      else
        sline ok "osv-scanner: no advisories"
      fi
    else
      # osv-scanner exits non-zero and may emit nothing when there are simply no
      # findings; only flag it when it produced no parseable output AND logged an error.
      if grep -qiE 'error|panic|failed' "$olog" 2>/dev/null; then
        t_osv=-1
        sline err "osv-scanner: SCAN ERROR (see ${olog})"
        issues+=("${label}: osv-scanner did not complete")
      else
        sline ok "osv-scanner: no advisories"
      fi
    fi
  fi

  # 5) integrity: content-hash verify the whole closure. A mismatch means a store
  # path is corrupted or was tampered with.
  local ilog="$out_dir/integrity-${safe}.log"
  if "${nix[@]}" store verify --recursive "$path" >"$ilog" 2>&1; then
    sline ok "integrity:   closure verified, no corruption"
  else
    # `--recursive` without --sigs still fails on genuine hash mismatches; a
    # signature-only complaint is handled by the provenance step below.
    if grep -qiE 'is corrupt|hash mismatch|is missing|unexpected' "$ilog" 2>/dev/null; then
      t_integrity="corrupt"
      sline err "integrity:   CORRUPTION DETECTED -> ${ilog}"
      note_worst critical
      issues+=("${label}: store closure failed integrity verification (corruption)")
    else
      sline ok "integrity:   verified (no content corruption)"
    fi
  fi

  # 6) provenance: how many closure paths carry no trusted signature. Locally
  # built paths (RF Swift's own derivations) are legitimately unsigned; a high
  # count on a supposedly cache-backed environment is a supply-chain signal.
  local plog="$out_dir/provenance-${safe}.log" unsigned
  "${nix[@]}" store verify --recursive --sigs "$path" >"$plog" 2>&1 || true
  # grep -c prints the count but exits 1 when it is zero; swallow that so the
  # count is not doubled, then normalise to an integer.
  unsigned=$(grep -ciE "lacks a (valid )?signature|not .*trusted|untrusted" "$plog" 2>/dev/null || true)
  [[ "$unsigned" =~ ^[0-9]+$ ]] || unsigned=0
  t_unsigned=$unsigned
  sline info "provenance:  ${unsigned} closure path(s) without a trusted signature (locally built or unsigned)"

  # 7) configuration warnings from evaluating this target (deprecations, insecure
  # markers, license/eval notes nixpkgs prints to stderr).
  local wlog="$out_dir/evalwarn-${safe}.log" warns
  "${nix[@]}" eval --raw ".#packages.${system}.\"${attr}\".drvPath" >/dev/null 2>"$wlog" || true
  warns=$(grep -ciE "warning:|deprecated|insecure|knownVulnerabilit" "$wlog" 2>/dev/null || true)
  [[ "$warns" =~ ^[0-9]+$ ]] || warns=0
  t_warns=$warns
  if [[ "$warns" -gt 0 ]]; then
    sline warn "config:      ${warns} evaluation warning(s) (deprecation/insecure) -> ${wlog}"
    if grep -qiE "insecure|knownVulnerabilit" "$wlog" 2>/dev/null; then
      note_worst medium
      issues+=("${label}: evaluation reports insecure / known-vulnerable package(s)")
    fi
  else
    sline ok "config:      no evaluation warnings"
  fi

  emit_target_json "$label" "$path" "$t_vulnix" "$t_components" \
    "$t_gc" "$t_gh" "$t_gm" "$t_gl" "$t_osv" "$t_integrity" "$t_unsigned" "$t_warns" "$t_vulnix_findings"
}

# -------- scan a container image (docker/podman OCI ref) --------------------
# grype, trivy and syft understand OCI images natively (OS packages + language
# layers), so this is the container-engine counterpart of scan_target. It reads
# the image from the local docker/podman daemon (or a registry ref).
scan_image() {
  local ref="$1"
  local safe=${ref//[^A-Za-z0-9._-]/_}
  local t_gc=0 t_gh=0 t_gm=0 t_gl=0 t_osv=0 t_components=0 t_trivy=0
  log ""
  log "=== image:${ref} ==="

  # 1) syft SBOM (CycloneDX) of the image.
  local sbom="$out_dir/sbom-image-${safe}.cdx.json" slog="$out_dir/syft-image-${safe}.log"
  run_tool syft scan "${ref}" -o "cyclonedx-json=${sbom}" -q >/dev/null 2>"$slog" || true
  if [[ -s "$sbom" ]]; then
    t_components=$(jq '.components|length' "$sbom" 2>/dev/null || echo 0)
    sline ok "syft:        SBOM -> ${sbom} (${t_components} components)"
  else
    t_components=-1
    sline err "syft:        SBOM generation failed (see ${slog}); is the image present? (docker/podman pull ${ref})"
    issues+=("image:${ref}: syft SBOM failed")
  fi

  # 2) grype scans the image natively (NVD + GHSA), with SARIF.
  local gjson="$out_dir/grype-image-${safe}.json" gsarif="$out_dir/grype-image-${safe}.sarif" glog="$out_dir/grype-image-${safe}.log"
  run_tool grype "${ref}" -o json="$gjson" -o sarif="$gsarif" -q >/dev/null 2>"$glog" || true
  if [[ -s "$gjson" ]] && jq -e . "$gjson" >/dev/null 2>&1; then
    gsev() { jq --arg s "$1" '[.matches[]|select((.vulnerability.severity//""|ascii_downcase)==$s)]|length' "$gjson" 2>/dev/null || echo 0; }
    t_gc=$(gsev critical); t_gh=$(gsev high); t_gm=$(gsev medium); t_gl=$(gsev low)
    local counts
    counts=$(jq -r '[.matches[].vulnerability.severity] | group_by(ascii_downcase) | map("\(.[0])=\(length)") | join(" ")' "$gjson" 2>/dev/null || echo "")
    if [[ -z "$counts" ]]; then sline ok "grype:       no findings -> ${gjson}"; else sline warn "grype:       ${counts} -> ${gjson}"; fi
    local sev
    while IFS= read -r sev; do
      [[ -z "$sev" ]] && continue; note_worst "$sev"
      [[ "$(sev_rank "$sev")" -ge 3 ]] && issues+=("image:${ref}: grype ${sev} finding(s)")
    done < <(jq -r '.matches[].vulnerability.severity' "$gjson" 2>/dev/null | sort -u)
  else
    t_gc=-1
    sline err "grype:       SCAN ERROR (see ${glog})"; issues+=("image:${ref}: grype did not complete")
  fi

  # 3) trivy image scan (the purpose-built OCI scanner; second source).
  local tjson="$out_dir/trivy-image-${safe}.json" tlog="$out_dir/trivy-image-${safe}.log"
  run_tool trivy image --quiet --format json --output "$tjson" "${ref}" >/dev/null 2>"$tlog" || true
  if [[ -s "$tjson" ]] && jq -e . "$tjson" >/dev/null 2>&1; then
    t_trivy=$(jq '[.Results[]?.Vulnerabilities[]?] | length' "$tjson" 2>/dev/null || echo 0)
    local tcrit
    tcrit=$(jq '[.Results[]?.Vulnerabilities[]?|select(.Severity=="CRITICAL")]|length' "$tjson" 2>/dev/null || echo 0)
    if [[ "$t_trivy" -gt 0 ]]; then
      sline warn "trivy:       ${t_trivy} vuln(s) (${tcrit} critical) -> ${tjson}"
      [[ "$tcrit" -gt 0 ]] && { note_worst critical; issues+=("image:${ref}: trivy ${tcrit} critical"); } || note_worst high
    else
      sline ok "trivy:       no vulnerabilities"
    fi
  else
    t_trivy=-1
    sline err "trivy:       SCAN ERROR (see ${tlog})"; issues+=("image:${ref}: trivy did not complete")
  fi

  # 4) osv-scanner against the SBOM.
  if [[ -s "$sbom" ]]; then
    local ojson="$out_dir/osv-image-${safe}.json" olog="$out_dir/osv-image-${safe}.log"
    run_tool osv-scanner --format json --sbom="$sbom" >"$ojson" 2>"$olog" || true
    if [[ -s "$ojson" ]] && jq -e . "$ojson" >/dev/null 2>&1; then
      t_osv=$(jq '[.results[]?.packages[]?.vulnerabilities[]?] | length' "$ojson" 2>/dev/null || echo 0)
      if [[ "$t_osv" -gt 0 ]]; then sline warn "osv-scanner: ${t_osv} advisory match(es) -> ${ojson}"; note_worst high; issues+=("image:${ref}: osv ${t_osv} advisories"); else sline ok "osv-scanner: no advisories"; fi
    fi
  fi

  target_json+=("$(jq -n --arg label "image:${ref}" --arg closure "$ref" \
    --argjson components "$t_components" --argjson gc "$t_gc" --argjson gh "$t_gh" \
    --argjson gm "$t_gm" --argjson gl "$t_gl" --argjson osv "$t_osv" --argjson trivy "$t_trivy" \
    '{label:$label, image:$closure, sbom_components:$components,
      grype:{critical:$gc,high:$gh,medium:$gm,low:$gl}, trivy_vulns:$trivy,
      osv_advisories:$osv}')")
}

# -------- repository-level supply-chain & configuration hygiene (once) -------
repo_checks() {
  log ""
  log "=== repository supply-chain & configuration ==="

  # Every flake.lock input pinned by content hash.
  local unpinned
  unpinned=$(jq -r '.nodes | to_entries[]
    | select(.key != "root")
    | select((.value.locked // {}) | has("narHash") | not)
    | .key' flake.lock 2>/dev/null)
  if [[ -n "$unpinned" ]]; then
    repo_locked=false; repo_unpinned=$(echo "$unpinned" | tr '\n' ' ')
    sline warn "flake.lock:  UNPINNED input(s): ${repo_unpinned}"
    note_worst medium
    issues+=("flake.lock has unpinned input(s): ${repo_unpinned}")
  else
    sline ok "flake.lock:  all inputs pinned by narHash"
  fi

  # Placeholder / unpinned source hashes left in the package set are a
  # supply-chain hole (the fetch is not content-addressed).
  local ph
  ph=$(grep -rInE "fakeHash|fakeSha256|sha256-A{20,}|sha256:?0{40,}" pkgs/ 2>/dev/null | grep -viE "^\s*#|placeholder\." | wc -l)
  repo_placeholder=$ph
  if [[ "$ph" -gt 0 ]]; then
    sline warn "hashes:      ${ph} placeholder/unpinned source hash(es) in pkgs/ -> supply-chain risk"
    note_worst medium
    issues+=("pkgs/ contains ${ph} placeholder/unpinned source hash(es)")
  else
    sline ok "hashes:      no placeholder source hashes in pkgs/"
  fi

  # Insecure-package escape hatches, flagged for review (not necessarily wrong).
  local ins
  ins=$(grep -rInE "permittedInsecurePackages|allowInsecure\s*=\s*true" . --include=*.nix 2>/dev/null | grep -vcE "^\s*#" || true)
  [[ "$ins" =~ ^[0-9]+$ ]] || ins=0
  repo_insecure=$ins
  if [[ "$ins" -gt 0 ]]; then
    sline warn "insecure:    ${ins} allowInsecure/permittedInsecurePackages reference(s) - review"
    issues+=("${ins} insecure-package allowance(s) present - review")
  else
    sline ok "insecure:    no insecure-package allowances"
  fi
}

log "RF Swift Nix security audit"
log "system:   ${system}"
log "output:   ${out_dir}"
log "fail-on:  ${fail_on}"
log "targets:  envs=[${envs[*]:-}] pkgs=[${pkgs[*]:-}] images=[${images[*]:-}]"

# Repository (flake) hygiene applies to the Nix side; skip it for a pure image
# audit, where the flake is not the subject.
if [[ ${#envs[@]} -gt 0 || ${#pkgs[@]} -gt 0 ]]; then
  repo_checks
fi

for e in "${envs[@]}"; do
  path=$(realise "$e")
  if [[ -n "$path" ]]; then scan_target "env:$e" "$e" "$path"; else
    log ""; log "=== env:$e ==="; log "  SKIP: could not realise (build failed or --no-build and not in store)"
    issues+=("env:$e: could not realise closure")
  fi
done
for p in "${pkgs[@]}"; do
  path=$(realise "$p")
  if [[ -n "$path" ]]; then scan_target "$p" "$p" "$path"; else
    log ""; log "=== $p ==="; log "  SKIP: could not realise"
    issues+=("$p: could not realise")
  fi
done
for img in "${images[@]}"; do
  scan_image "$img"
done

# -------- final report ------------------------------------------------------
log ""
log "================ AUDIT REPORT ================"
if [[ ${#issues[@]} -eq 0 ]]; then
  sline ok "ALL GREEN - no issues across all completed scans"
else
  # Banner severity: red for high/critical, yellow otherwise.
  if [[ $worst_rank -ge 3 ]]; then
    sline err "ISSUES FOUND (${#issues[@]}) - worst severity: $(rank_name "$worst_rank")"
  else
    sline warn "ISSUES FOUND (${#issues[@]}) - worst severity: $(rank_name "$worst_rank")"
  fi
  for i in "${issues[@]}"; do
    if [[ "$i" == *corruption* || "$i" == *critical* || "$i" == *"CVE"* || "$i" == *high* ]]; then
      sline err "$i"
    else
      sline warn "$i"
    fi
  done
fi
log "Full reports and SBOMs: ${out_dir}"
log "============================================="

# -------- machine/report renderings (json / html / pdf) ---------------------
worst_name=$(rank_name "$worst_rank")
generated=$(date -u +%Y-%m-%dT%H:%M:%SZ 2>/dev/null || echo "")

if want_fmt json || want_fmt html || want_fmt pdf; then
  # Aggregate everything collected during the run into one JSON object; html/pdf
  # are rendered from it so all three formats agree.
  if [[ ${#target_json[@]} -gt 0 ]]; then
    targets_arr=$(printf '%s\n' "${target_json[@]}" | jq -s '.')
  else targets_arr="[]"; fi
  if [[ ${#issues[@]} -gt 0 ]]; then
    issues_arr=$(printf '%s\n' "${issues[@]}" | jq -R . | jq -s 'map(select(length>0))')
  else issues_arr="[]"; fi
  repo_json=$(jq -n --argjson locked "$repo_locked" --arg unpinned "$repo_unpinned" \
    --argjson placeholder "$repo_placeholder" --argjson insecure "$repo_insecure" \
    '{flake_locked:$locked, unpinned_inputs:($unpinned|gsub("^ +| +$";"")), placeholder_hashes:$placeholder, insecure_allowances:$insecure}')
  targets_input="$out_dir/.targets.json"
  issues_input="$out_dir/.issues.json"
  printf '%s\n' "$targets_arr" > "$targets_input"
  printf '%s\n' "$issues_arr" > "$issues_input"
  report_json=$(jq -n \
    --arg system "$system" --arg generated "$generated" --arg worst "$worst_name" --arg fail_on "$fail_on" \
    --argjson repository "$repo_json" --slurpfile targets "$targets_input" --slurpfile issues "$issues_input" \
    '{tool:"rfswift security-audit", system:$system, generated:$generated,
      worst_severity:$worst, fail_on:$fail_on, ok:($issues[0]|length==0),
      repository:$repository, targets:$targets[0], issues:$issues[0]}')
  rm -f "$targets_input" "$issues_input"

  if want_fmt json; then
    printf '%s\n' "$report_json" > "$out_dir/report.json"
    log "Wrote ${out_dir}/report.json"
  fi

  if want_fmt html || want_fmt pdf; then
    html="$out_dir/report.html"
    {
      cat <<'HTMLHEAD'
<!doctype html><html><head><meta charset="utf-8"><title>RF Swift security audit</title>
<style>
 body{font-family:system-ui,Arial,sans-serif;margin:2rem;color:#1b1f24}
 h1{font-size:1.5rem} h2{margin-top:1.6rem;font-size:1.1rem}
 .meta{color:#57606a;font-size:.9rem}
 .banner{padding:.7rem 1rem;border-radius:8px;font-weight:600;margin:1rem 0}
 .green{background:#d3f9d8;color:#0b6b2e} .red{background:#ffe3e3;color:#a4133c} .yellow{background:#fff3bf;color:#8a6d00}
 table{border-collapse:collapse;width:100%;margin:.6rem 0;font-size:.92rem}
 th,td{border:1px solid #d0d7de;padding:.35rem .55rem;text-align:left}
 th{background:#f6f8fa} td.n{text-align:right}
 .ok{color:#0b6b2e} .warn{color:#8a6d00} .err{color:#a4133c} code{font-size:.85em}
 ul.issues li{margin:.15rem 0}
</style></head><body>
HTMLHEAD
      printf '<h1>RF Swift Nix security audit</h1>\n'
      printf '<p class="meta">system: %s &nbsp;|&nbsp; generated: %s &nbsp;|&nbsp; fail-on: %s</p>\n' \
        "$(printf '%s' "$system")" "$generated" "$fail_on"
      if [[ ${#issues[@]} -eq 0 ]]; then
        printf '<div class="banner green">&#9989; ALL GREEN &mdash; no issues across all completed scans</div>\n'
      elif [[ $worst_rank -ge 3 ]]; then
        printf '<div class="banner red">&#10060; ISSUES FOUND (%s) &mdash; worst severity: %s</div>\n' "${#issues[@]}" "$worst_name"
      else
        printf '<div class="banner yellow">&#9888;&#65039; ISSUES FOUND (%s) &mdash; worst severity: %s</div>\n' "${#issues[@]}" "$worst_name"
      fi
      # Repository section.
      printf '<h2>Repository supply-chain &amp; configuration</h2>\n'
      printf '%s' "$report_json" | jq -r '
        .repository as $r |
        "<table><tr><th>Check</th><th>Result</th></tr>" +
        "<tr><td>flake.lock fully pinned</td><td class=\"\($r.flake_locked|if . then "ok\">&#9989; yes" else "err\">&#10060; no: "+$r.unpinned_inputs end)</td></tr>" +
        "<tr><td>placeholder/unpinned source hashes in pkgs/</td><td class=\"\($r.placeholder_hashes|if .>0 then "warn\">&#9888;&#65039; "+(.|tostring) else "ok\">&#9989; 0" end)</td></tr>" +
        "<tr><td>insecure-package allowances</td><td class=\"\($r.insecure_allowances|if .>0 then "warn\">&#9888;&#65039; "+(.|tostring) else "ok\">&#9989; 0" end)</td></tr>" +
        "</table>"'
      # Per-target table.
      printf '<h2>Scanned targets</h2>\n'
      printf '%s' "$report_json" | jq -r '
        "<table><tr><th>Target</th><th>vulnix CVEs</th><th>grype C/H/M/L</th><th>OSV</th><th>SBOM</th><th>integrity</th><th>unsigned</th><th>eval warns</th></tr>" +
        (.targets | map(
          "<tr><td><code>\(.label)</code></td>" +
          "<td class=\"n \(if .vulnix_cves>0 then "warn" elif .vulnix_cves<0 then "err" else "ok" end)\">\(if .vulnix_cves<0 then "err" else .vulnix_cves|tostring end)</td>" +
          "<td class=\"n \(if .grype.critical>0 or .grype.high>0 then "err" elif .grype.medium>0 or .grype.low>0 then "warn" else "ok" end)\">\(.grype.critical)/\(.grype.high)/\(.grype.medium)/\(.grype.low)</td>" +
          "<td class=\"n \(if .osv_advisories>0 then "warn" else "ok" end)\">\(if .osv_advisories<0 then "err" else .osv_advisories|tostring end)</td>" +
          "<td class=\"n\">\(.sbom_components)</td>" +
          "<td class=\"\(if .integrity=="ok" then "ok\">&#9989; ok" else "err\">&#10060; corrupt" end)</td>" +
          "<td class=\"n\">\(.unsigned_paths)</td>" +
          "<td class=\"n \(if .eval_warnings>0 then "warn" else "ok" end)\">\(.eval_warnings)</td></tr>"
        ) | join("")) + "</table>"'
      # Issues list.
      if [[ ${#issues[@]} -gt 0 ]]; then
        printf '<h2>Potential issues</h2>\n<ul class="issues">\n'
        printf '%s' "$report_json" | jq -r '.issues[] | "<li>\(. | @html)</li>"'
        printf '</ul>\n'
      fi
      printf '<p class="meta">Full per-tool reports and SBOMs are in <code>%s</code>.</p>\n' "$out_dir"
      printf '</body></html>\n'
    } > "$html"
    want_fmt html && log "Wrote ${html}"

    if want_fmt pdf; then
      # weasyprint renders the styled HTML (colours + emoji) to PDF; it ships as
      # a python module with a `weasyprint` entry point.
      if run_tool python3Packages.weasyprint "$html" "$out_dir/report.pdf" >/dev/null 2>"$out_dir/pdf.log"; then
        log "Wrote ${out_dir}/report.pdf"
      else
        echo "warning: PDF generation failed (see ${out_dir}/pdf.log); HTML report is available." >&2
      fi
    fi
    # If HTML was only needed as the PDF source, drop it unless requested.
    want_fmt html || rm -f "$html"
  fi
fi

# -------- optional gate (only affects the exit code) ------------------------
gate_rank=$(sev_rank "$fail_on")
if [[ "$fail_on" != none && $gate_rank -gt 0 && $worst_rank -ge $gate_rank ]]; then
  echo "::error::security audit found findings at or above '${fail_on}' (worst: $(rank_name "$worst_rank"))." >&2
  exit 1
fi
# Report-only mode (the default): the audit ran, so it succeeded.
exit 0
