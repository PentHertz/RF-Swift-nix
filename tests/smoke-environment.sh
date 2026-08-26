#!/usr/bin/env bash
set -euo pipefail

if [[ $# -ne 1 ]]; then
  echo "usage: $0 <environment>" >&2
  exit 2
fi

repo=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
cd "$repo"
nix_cmd=(nix --extra-experimental-features "nix-command flakes")
environment=$1

if ! jq -e --arg name "$environment" '.environments[] | select(.name == $name)' catalog.json >/dev/null; then
  echo "unknown environment: $environment" >&2
  exit 2
fi

echo "Building $environment closure..."
out=$("${nix_cmd[@]}" build ".#$environment" --no-link --print-out-paths --print-build-logs)

echo "Checking declared main programs in $out..."
programs=$("${nix_cmd[@]}" eval --impure --json --expr "
  let
    f = builtins.getFlake (toString ./.);
    lib = f.inputs.nixpkgs.lib;
    lp = f.legacyPackages.\${builtins.currentSystem};
    names = f.catalog.${environment}.packages;
    package = n: lib.attrByPath (lib.splitString \".\" n) null lp;
    main = n: let p = package n; in
      if p == null then null else (p.meta.mainProgram or null);
  in builtins.listToAttrs (map (n: { name = n; value = main n; }) names)
")

checked=0
while IFS=$'\t' read -r package program; do
  [[ -n "$program" ]] || continue
  if [[ ! -x "$out/bin/$program" ]]; then
    echo "ERROR: $package declares mainProgram '$program', absent from $environment/bin" >&2
    exit 1
  fi
  printf '  %-38s %s\n' "$package" "$program"
  checked=$((checked + 1))
done < <(jq -r 'to_entries[] | [.key, (.value // "")] | @tsv' <<<"$programs")

echo "$environment passed: closure built and $checked declared commands are executable."
