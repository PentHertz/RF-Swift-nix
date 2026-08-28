#!/usr/bin/env bash
set -euo pipefail

repo=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
cd "$repo"

nix_cmd=(nix --extra-experimental-features "nix-command flakes")
system=${RFSWIFT_TEST_SYSTEM:-$("${nix_cmd[@]}" eval --raw --impure --expr builtins.currentSystem)}
generated=$(mktemp)
trap 'rm -f "$generated"' EXIT

echo "[1/5] catalog.json is valid and generated from environments.nix"
jq -e '.version and (.environments | type == "array" and length > 0)' catalog.json >/dev/null
"${nix_cmd[@]}" eval --json --file ./gen-catalog.nix >"$generated"
diff -u <(jq -S . catalog.json) <(jq -S . "$generated")

echo "[2/5] prerequisite layers are valid and SDR profiles match image layering"
jq -e '
  all(.environments[]; . as $e |
    (($e.prerequisites // []) | all(. as $p | ($e.packages | index($p)) != null))) and
  ((.environments[] | select(.name == "sdr_light") | .packages) | index("gnuradio-rfswift-light") != null) and
  ((.environments[] | select(.name == "sdr_light") | .packages) | index("gnuradio-rfswift") == null) and
  ((.environments[] | select(.name == "sdr_full") | .packages) | index("gnuradio-rfswift") != null)
' catalog.json >/dev/null

echo "[3/5] every environment forces to an installable derivation on $system"
mapfile -t environments < <(jq -r '.environments[].name' catalog.json)
for environment in "${environments[@]}"; do
  printf '  %-16s' "$environment"
  "${nix_cmd[@]}" eval --raw ".#packages.${system}.\"${environment}\".drvPath" >/dev/null
  echo ok
done

echo "[4/5] all exposed custom packages force to derivations on $system"
# Do this one derivation per Nix process. A monolithic `nix flake check` retains
# the complete graph and can consume many GiB for this package set.
mapfile -t custom_packages < <(
  "${nix_cmd[@]}" eval --json ".#packages.${system}" --apply builtins.attrNames \
    | jq -r '.[] | select(startswith("pkg-"))'
)
for package in "${custom_packages[@]}"; do
  printf '  %-38s' "$package"
  "${nix_cmd[@]}" eval --raw ".#packages.${system}.\"${package}\".drvPath" >/dev/null
  echo ok
done

# Python 3.10-only custom tools are supplied by a separate nixpkgs pin, which
# the generic overlay cannot carry. They must still be exposed by their catalog
# names because `rfswift nix install` resolves through legacyPackages.
for package in mirage bluing; do
  printf '  legacyPackages.%-23s' "$package"
  "${nix_cmd[@]}" eval --raw ".#legacyPackages.${system}.\"${package}\".drvPath" >/dev/null
  echo ok
done

echo "[5/5] RF Swift's embedded catalog matches, when a sibling checkout exists"
embedded=../RF-Swift/go/rfswift/nix/catalog.json
if [[ -f "$embedded" ]]; then
  diff -u <(jq -S . catalog.json) <(jq -S . "$embedded")
else
  echo "  skipped (RF-Swift sibling checkout not present)"
fi

echo "RF-Swift-nix evaluation ground truth passed."
