#!/usr/bin/env bash
set -euo pipefail

root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
cd "$root"

scripts/package-maintenance.sh audit

# Exercise package scaffolding without changing the checkout.
fixture=$(mktemp -d)
trap 'rm -rf "$fixture"' EXIT
mkdir -p "$fixture/scripts" "$fixture/templates/packages" "$fixture/pkgs"
cp scripts/package-maintenance.sh "$fixture/scripts/"
cp templates/packages/*.nix "$fixture/templates/packages/"
cp pkgs/default.nix "$fixture/pkgs/default.nix"
touch "$fixture/flake.nix"
RFSWIFT_MAINTENANCE_ROOT="$fixture" \
  "$fixture/scripts/package-maintenance.sh" new fixture-tool go example/project \
    --rev 0123456789abcdef0123456789abcdef01234567 >/dev/null
grep -q 'fixture-tool = callPackage ./fixture-tool.nix' "$fixture/pkgs/default.nix"
grep -q 'rev = "0123456789abcdef0123456789abcdef01234567"' "$fixture/pkgs/fixture-tool.nix"
grep -q 'updateBranch = ""' "$fixture/pkgs/fixture-tool.nix"
nix-instantiate --parse "$fixture/pkgs/fixture-tool.nix" >/dev/null

for type in rust python cmake; do
  name="fixture-$type"
  RFSWIFT_MAINTENANCE_ROOT="$fixture" \
    "$fixture/scripts/package-maintenance.sh" new "$name" "$type" example/project \
      --rev 0123456789abcdef0123456789abcdef01234567 >/dev/null
  grep -q "build = \"$type\"" "$fixture/pkgs/$name.nix"
  nix-instantiate --parse "$fixture/pkgs/$name.nix" >/dev/null
done

RFSWIFT_MAINTENANCE_ROOT="$fixture" \
  "$fixture/scripts/package-maintenance.sh" new fixture-binary binary \
    https://example.invalid/fixture-binary.tar.gz >/dev/null
grep -q 'url = "https://example.invalid/fixture-binary.tar.gz"' "$fixture/pkgs/fixture-binary.nix"
nix-instantiate --parse "$fixture/pkgs/fixture-binary.nix" >/dev/null

echo "Package maintenance workflow tests passed."
