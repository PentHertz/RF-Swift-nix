#!/usr/bin/env bash
set -uo pipefail

system=${1:?usage: build-cache-report.sh <nix-system> <environment> <report-dir>}
environment=${2:?missing environment}
report_dir=${3:?missing report directory}
mkdir -p "$report_dir"
log="$report_dir/build.log"
summary="$report_dir/summary.md"
json="$report_dir/result.json"
started=$(date -u +%FT%TZ)
attr=".#packages.${system}.${environment}"

set +e
nix build "$attr" --no-link --print-build-logs --keep-going 2>&1 | tee "$log"
status=${PIPESTATUS[0]}
# Everything below is best-effort reporting: it must never mask $status.
finished=$(date -u +%FT%TZ)

if [ "$status" -eq 0 ]; then result=success; else result=failure; fi
jq -n \
  --arg system "$system" --arg environment "$environment" \
  --arg attribute "$attr" --arg result "$result" \
  --arg started "$started" --arg finished "$finished" \
  --argjson exitCode "$status" \
  '{system:$system,environment:$environment,attribute:$attribute,result:$result,exitCode:$exitCode,started:$started,finished:$finished}' > "$json"

{
  echo "# RF Swift Nix cache build"
  echo
  echo "- Version: \`v1.0.0-dev\`"
  echo "- System: \`$system\`"
  echo "- Environment: \`$environment\`"
  echo "- Result: **$result**"
  echo "- Exit code: \`$status\`"
  echo "- Started: \`$started\`"
  echo "- Finished: \`$finished\`"
  echo "- Disk free at end: \`$(df -h / | awk 'NR==2{print $4 " of " $2}')\`"
  if [ "$status" -ne 0 ]; then
    # Nix's own verdict first: which derivations actually failed, and the
    # dependency chain up to the environment. This is the signal; everything
    # else below is context.
    echo
    echo "## Failed derivations"
    echo
    echo '```text'
    # Besides builder failures, catch the non-builder ways a derivation fails:
    # a substitute (cache download) that could not be fetched, a fixed-output
    # hash mismatch (moving upstream git ref), or the runner disk filling up.
    LC_ALL=C grep -aiE '^error: (builder for|[0-9]+ dependencies of derivation|some substitutes for|hash mismatch|unable to download|cannot build|writing to file)|no space left on device|exceeded the maximum execution time' "$log" | tail -40 \
      || echo "(no 'error: builder for' line - the build was killed or ran out of time/space)"
    echo '```'
    # For each failed builder, its own last lines (the test summary / compiler
    # error), keyed on the "<pname>> " log prefix nix uses with -L.
    echo
    echo "## Failure context"
    echo
    echo '```text'
    LC_ALL=C grep -aoE "^error: builder for '/nix/store/[^']+\.drv'" "$log" \
      | sed -E "s#^error: builder for '/nix/store/[a-z0-9]{32}-(.+)\.drv'#\1#" | sort -u | head -10 \
      | while IFS= read -r drv; do
          # nix -L prefixes each line with the derivation name; match the name
          # without its version ("python3.14-urwid-3.0.5" -> "python3.14-urwid").
          prefix=$(printf '%s' "$drv" | sed -E 's/-[0-9][^-]*$//')
          echo "### $drv"
          LC_ALL=C grep -aE "^${prefix}[^>]*> " "$log" \
            | grep -aE 'error|Error|FAIL|failed|Traceback|assert|Exception|No space|timed out|Killed' \
            | tail -25 || true
          echo
        done
    echo '```'
    echo
    echo "## Other diagnostics"
    echo
    echo '```text'
    LC_ALL=C grep -aiE 'hash mismatch|specified:|got:|no space|disk.*full|cannot build|exceeded the maximum execution time|signal|killed|substituter|unable to download|HTTP error' "$log" | tail -20 || true
    echo '```'
  fi
} > "$summary"

cat "$summary" >> "${GITHUB_STEP_SUMMARY:-/dev/null}"
exit "$status"
