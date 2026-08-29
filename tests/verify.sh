#!/usr/bin/env bash
set -euo pipefail

repo=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
cd "$repo"

nix_cmd=(nix --extra-experimental-features "nix-command flakes")
flake_ref=${RFSWIFT_TEST_FLAKE_REF:-.}
system=${RFSWIFT_TEST_SYSTEM:-$("${nix_cmd[@]}" eval --raw --impure --expr builtins.currentSystem)}
generated=$(mktemp)
trap 'rm -f "$generated"' EXIT

echo "[1/6] maintenance metadata and scripts are valid"
./tests/maintenance.sh

echo "[2/6] catalog.json is valid and generated from environments.nix"
jq -e '.version and (.environments | type == "array" and length > 0)' catalog.json >/dev/null
"${nix_cmd[@]}" eval --json --file ./gen-catalog.nix >"$generated"
diff -u <(jq -S . catalog.json) <(jq -S . "$generated")

echo "[3/6] prerequisite layers are valid and SDR profiles match image layering"
jq -e '
  all(.environments[]; . as $e |
    (($e.prerequisites // []) | all(. as $p | ($e.packages | index($p)) != null))) and
  ((.environments[] | select(.name == "sdr_light") | .packages) | index("gnuradio-rfswift-light") != null) and
  ((.environments[] | select(.name == "sdr_light") | .packages) | index("gnuradio-rfswift") == null) and
  ((.environments[] | select(.name == "sdr_full") | .packages) | index("gnuradio-rfswift") != null)
' catalog.json >/dev/null

echo "[4/6] every environment forces to an installable derivation on $system"
# `mapfile` is bash 4+; read into the array portably so this also runs under the
# bash 3.2 that ships on macOS.
environments=()
while IFS= read -r line; do environments+=("$line"); done \
  < <(jq -r '.environments[].name' catalog.json)
for environment in "${environments[@]}"; do
  printf '  %-16s' "$environment"
  "${nix_cmd[@]}" eval --raw "${flake_ref}#packages.${system}.\"${environment}\".drvPath" >/dev/null
  echo ok
done

echo "[5/6] all exposed custom packages force to derivations on $system"
# Do this one derivation per Nix process. A monolithic `nix flake check` retains
# the complete graph and can consume many GiB for this package set.
custom_packages=()
while IFS= read -r line; do custom_packages+=("$line"); done < <(
  "${nix_cmd[@]}" eval --json "${flake_ref}#packages.${system}" --apply builtins.attrNames \
    | jq -r '.[] | select(startswith("pkg-"))'
)
# A custom package is expected to force everywhere it is *available*. Many are
# legitimately Linux-only (proprietary vendor SDKs, SocketCAN tools, ...), so on
# a non-Linux host forcing them raises "not available on the requested
# hostPlatform"; that is a skip, not a failure. Anything else is a real break.
force_or_skip() {
  local attr=$1 label=$2 out
  printf '  %-38s' "$label"
  if out=$("${nix_cmd[@]}" eval --raw "$attr" 2>&1); then
    echo ok
  elif printf '%s' "$out" | grep -q "not available on the requested hostPlatform"; then
    echo "skipped (unavailable on ${system})"
  else
    printf '\n%s\n' "$out" >&2
    exit 1
  fi
}

for package in "${custom_packages[@]}"; do
  force_or_skip "${flake_ref}#packages.${system}.\"${package}\".drvPath" "$package"
done

# Python 3.10-only custom tools are supplied by a separate nixpkgs pin, which
# the generic overlay cannot carry. They must still be exposed by their catalog
# names because `rfswift nix install` resolves through legacyPackages.
for package in mirage bluing; do
  force_or_skip "${flake_ref}#legacyPackages.${system}.\"${package}\".drvPath" "legacyPackages.${package}"
done

echo "[6/6] RF Swift's embedded catalog matches, when a sibling checkout exists"
embedded=../RF-Swift/go/rfswift/nix/catalog.json
if [[ -f "$embedded" ]]; then
  diff -u <(jq -S . catalog.json) <(jq -S . "$embedded")
else
  echo "  skipped (RF-Swift sibling checkout not present)"
fi

echo "RF-Swift-nix evaluation ground truth passed."
