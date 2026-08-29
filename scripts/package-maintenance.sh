#!/usr/bin/env bash
set -euo pipefail

root=${RFSWIFT_MAINTENANCE_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}
[[ -f "$root/flake.nix" && -d "$root/pkgs" ]] || {
  echo "error: run from an RF-Swift-nix checkout" >&2
  exit 2
}
cd "$root"
nix_cmd=(nix --extra-experimental-features "nix-command flakes")
flake_ref=${RFSWIFT_FLAKE_REF:-.}

usage() {
  cat <<'EOF'
RF Swift package maintenance

  package-maintenance.sh new NAME TYPE OWNER/REPO [--branch BRANCH | --rev COMMIT]
  package-maintenance.sh new NAME binary DOWNLOAD_URL
  package-maintenance.sh prefetch NAME
  package-maintenance.sh update NAME [--version VERSION]
  package-maintenance.sh check NAME [--no-build]
  package-maintenance.sh vendor-report [--check-urls]
  package-maintenance.sh vendor-update NAME VERSION URL [--system SYSTEM]
  package-maintenance.sh catalog
  package-maintenance.sh audit

TYPE is one of: go, rust, python, cmake, binary. See docs/adding-packages.md.
EOF
}

die() { echo "error: $*" >&2; exit 2; }
valid_name() { [[ "$1" =~ ^[a-zA-Z0-9][a-zA-Z0-9+._-]*$ ]]; }
package_file() {
  local name=$1 found
  found=$(find pkgs -type f -name "${name}.nix" -print -quit)
  [[ -n "$found" ]] || die "package '$name' has no pkgs/**/${name}.nix"
  printf '%s\n' "$found"
}

new_package() {
  [[ $# -ge 3 ]] || die "new requires NAME TYPE OWNER/REPO"
  local name=$1 type=$2 upstream=$3 rev="" branch="main" owner repo template target today tmp
  shift 3
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --rev) rev=${2:?missing revision}; branch=""; shift 2 ;;
      --branch) branch=${2:?missing branch}; shift 2 ;;
      *) die "unknown option: $1" ;;
    esac
  done
  valid_name "$name" || die "invalid package name '$name'"
  [[ "$type" =~ ^(go|rust|python|cmake|binary)$ ]] || die "unsupported type '$type'"
  if [[ "$type" == binary ]]; then
    owner=""; repo=""; rev=""; branch=""
    [[ "$upstream" =~ ^https:// ]] || die "binary source must be an HTTPS URL"
  else
    [[ "$upstream" == */* ]] || die "upstream must be OWNER/REPO"
    owner=${upstream%%/*}; repo=${upstream#*/}
  fi
  if [[ "$type" != binary && -z "$rev" ]]; then
    rev=$(git ls-remote "https://github.com/$owner/$repo.git" "refs/heads/$branch" | awk 'NR == 1 { print $1 }')
    [[ -n "$rev" ]] || die "cannot resolve branch '$branch' for $upstream"
  fi
  template="templates/packages/${type}.nix"; target="pkgs/${name}.nix"
  [[ ! -e "$target" ]] || die "$target already exists"
  today=$(date -u +%Y-%m-%d); tmp=$(mktemp)
  sed -e "s|@NAME@|$name|g" -e "s|@OWNER@|$owner|g" \
      -e "s|@REPO@|$repo|g" -e "s|@REV@|$rev|g" \
      -e "s|@BRANCH@|$branch|g" \
      -e "s|@URL@|$upstream|g" \
      -e "s|@DATE@|$today|g" -e "s|@PYMODULE@|${name//-/_}|g" \
      "$template" > "$tmp"
  install -m 0644 "$tmp" "$target"
  rm -f "$tmp"
  sed -i "/## PACKAGE-MAINTENANCE: INSERT BEFORE/i\\  $name = callPackage ./$name.nix { };" pkgs/default.nix
  echo "Created $target and registered pkg-$name."
  echo "Next: edit its TODO fields, add '$name' to environments.nix, then run:"
  echo "  scripts/package-maintenance.sh prefetch $name"
  echo "  scripts/package-maintenance.sh check $name"
}

prefetch_package() {
  [[ $# -eq 1 ]] || die "prefetch requires NAME"
  local name=$1 file attempt output hash
  file=$(package_file "$name")
  for attempt in 1 2 3 4; do
    if output=$("${nix_cmd[@]}" build "${flake_ref}#pkg-$name" --no-link 2>&1); then
      echo "pkg-$name builds; all hashes are pinned."
      return 0
    fi
    hash=$(printf '%s\n' "$output" | sed -nE 's/.*got:[[:space:]]*(sha256-[A-Za-z0-9+\/=]+).*/\1/p' | tail -1)
    [[ -n "$hash" ]] || { printf '%s\n' "$output" >&2; die "failure was not a hash mismatch"; }
    if grep -q 'lib.fakeHash' "$file"; then
      sed -i "0,/lib.fakeHash/s|lib.fakeHash|\"$hash\"|" "$file"
    else
      # Replace the first stale SRI source hash; review the resulting diff.
      sed -i -E "0,/hash = \"sha256-[A-Za-z0-9+\/=]+\"/s||hash = \"$hash\"|" "$file"
    fi
    echo "Pinned hash $attempt in $file: $hash"
  done
  die "more than four hashes require attention; update the package manually"
}

update_package() {
  [[ $# -ge 1 ]] || die "update requires NAME"
  local name=$1 version="stable"; shift
  while [[ $# -gt 0 ]]; do
    case "$1" in --version) version=${2:?missing version}; shift 2 ;; *) die "unknown option: $1" ;; esac
  done
  "${nix_cmd[@]}" run --inputs-from . nixpkgs#nix-update -- \
    --flake --version "$version" "pkg-$name"
}

check_package() {
  [[ $# -ge 1 ]] || die "check requires NAME"
  local name=$1 build=1 drv out main
  shift; [[ ${1:-} == --no-build ]] && build=0
  drv=$("${nix_cmd[@]}" eval --raw "${flake_ref}#pkg-$name.drvPath")
  echo "Evaluates: $drv"
  "${nix_cmd[@]}" eval --json "${flake_ref}#pkg-$name.meta" | jq -e '.description and .license' >/dev/null
  if (( build )); then
    out=$("${nix_cmd[@]}" build --no-link --print-out-paths "${flake_ref}#pkg-$name")
    main=$("${nix_cmd[@]}" eval --raw "${flake_ref}#pkg-$name.meta.mainProgram" 2>/dev/null || true)
    [[ -z "$main" || -x "$out/bin/$main" ]] || die "meta.mainProgram '$main' is not executable"
    echo "Built: $out"
  fi
}

vendor_update() {
  [[ $# -ge 3 ]] || die "vendor-update requires NAME VERSION URL"
  local name=$1 version=$2 url=$3 system="" result hash tmp has_artifacts
  shift 3
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --system) system=${2:?missing system}; shift 2 ;;
      *) die "unknown option: $1" ;;
    esac
  done
  jq -e --arg n "$name" 'has($n)' pkgs/vendor/sources.json >/dev/null || die "unknown vendor '$name'"
  has_artifacts=$(jq -r --arg n "$name" '.[$n] | has("artifacts")' pkgs/vendor/sources.json)
  if [[ "$has_artifacts" == true && -z "$system" ]]; then
    die "$name has per-system artifacts; pass --system (for example x86_64-linux or aarch64-linux)"
  fi
  if [[ -n "$system" ]]; then
    jq -e --arg n "$name" --arg s "$system" '.[$n].platformPaths | has($s)' \
      pkgs/vendor/sources.json >/dev/null || die "$name does not support system '$system'"
  fi
  result=$("${nix_cmd[@]}" store prefetch-file --json "$url")
  hash=$(jq -r .hash <<<"$result"); tmp=$(mktemp)
  if [[ -n "$system" ]]; then
    jq --arg n "$name" --arg v "$version" --arg u "$url" --arg h "$hash" --arg s "$system" \
      '.[$n].version=$v | .[$n].artifacts[$s]={url:$u,hash:$h}
       | if $s == "x86_64-linux" then .[$n].url=$u | .[$n].hash=$h else . end' \
      pkgs/vendor/sources.json > "$tmp"
  else
    jq --arg n "$name" --arg v "$version" --arg u "$url" --arg h "$hash" \
      '.[$n].version=$v | .[$n].url=$u | .[$n].hash=$h' \
      pkgs/vendor/sources.json > "$tmp"
  fi
  mv "$tmp" pkgs/vendor/sources.json
  echo "Updated $name${system:+ for $system} to $version ($hash). Run: $0 check $name"
}

audit_repo() {
  local failed=0
  jq -e 'all(to_entries[]; .value.version and .value.url and .value.hash and .value.platformPaths)' \
    pkgs/vendor/sources.json >/dev/null || failed=1
  jq -e '
    all(to_entries[];
      (.value.artifacts // null) as $artifacts |
      ($artifacts == null or
        ((.value.platformPaths | keys | sort) == ($artifacts | keys | sort)) and
        all($artifacts[]; .url and .hash)))
  ' pkgs/vendor/sources.json >/dev/null || {
    echo "error: vendor artifacts must cover exactly every declared platform" >&2
    failed=1
  }
  if rg -n '^[[:space:]]*(hash|vendorHash|cargoHash)[[:space:]]*=.*lib\.(fakeHash|fakeSha256)|sha256-[A]{20,}' \
      pkgs --glob '*.nix'; then
    echo "error: placeholder hashes remain" >&2; failed=1
  fi
  bash -n scripts/*.sh pkgs/update.sh
  "${nix_cmd[@]}" eval --json --file gen-catalog.nix >/dev/null
  (( failed == 0 )) || exit 1
  echo "Maintenance audit passed."
}

command=${1:-}; [[ -n "$command" ]] || { usage; exit 2; }; shift
case "$command" in
  new) new_package "$@" ;;
  prefetch) prefetch_package "$@" ;;
  update) update_package "$@" ;;
  check) check_package "$@" ;;
  vendor-report) exec scripts/vendor-report.sh "$@" ;;
  vendor-update) vendor_update "$@" ;;
  catalog) "${nix_cmd[@]}" run "${flake_ref}#gen-catalog" ;;
  audit) audit_repo ;;
  help|-h|--help) usage ;;
  *) usage; die "unknown command '$command'" ;;
esac
