#!/usr/bin/env bash
#
# Refresh the source hashes of RF Swift's custom Nix packages.
#
# For each pkgs/<name>.nix that fetches a source, this builds .#pkg-<name>. Nix
# fetches the source first as a fixed-output derivation; if the recorded hash
# does not match, Nix reports the correct one, and this script writes it back.
# Use it to pin the initial `lib.fakeHash` placeholders, or later after you bump
# a package's `rev`/`version`.
#
# Vendor blobs (pkgs/vendor/, which use requireFile) are skipped: their hashes
# are set by hand from `nix hash file <file>`.
#
# Requires: nix with flakes enabled, and network. Run from the repo root:
#   bash pkgs/update.sh            # refresh everything
#   bash pkgs/update.sh readsb     # refresh one package
set -uo pipefail

NIXFLAGS=(--extra-experimental-features 'nix-command flakes')

# extract_hash reads the correct "got: sha256-..." value from a hash-mismatch
# message, preferring the "got" line so it never picks the wrong (specified) one.
extract_hash() {
  local got
  got=$(grep -iE 'got' <<<"$1" | grep -oE 'sha256-[A-Za-z0-9+/]{43}=' | tail -1)
  if [ -n "$got" ]; then
    echo "$got"
    return
  fi
  grep -oE 'sha256-[A-Za-z0-9+/]{43}=' <<<"$1" | tail -1
}

pin_one() {
  local attr="$1" file="$2" out got
  out=$(nix "${NIXFLAGS[@]}" build ".#pkg-${attr}" --no-link 2>&1)
  if [ $? -eq 0 ]; then
    echo "  ${attr}: builds, hash already correct"
    return 0
  fi
  got=$(extract_hash "$out")
  if [ -z "$got" ]; then
    echo "  ${attr}: no hash mismatch; build failed for another reason:"
    tail -6 <<<"$out" | sed 's/^/    /'
    return 1
  fi
  if grep -q 'lib.fakeHash' "$file"; then
    sed -i "s|lib.fakeHash|\"${got}\"|" "$file"
  else
    sed -i -E "s|hash = \"sha256-[A-Za-z0-9+/]{43}=\";|hash = \"${got}\";|" "$file"
  fi
  echo "  ${attr}: pinned ${got}"
}

main() {
  local only="${1:-}"
  for file in pkgs/*.nix; do
    local base
    base=$(basename "$file" .nix)
    case "$base" in
      default | README) continue ;;
    esac
    if [ -n "$only" ] && [ "$base" != "$only" ]; then continue; fi
    grep -q 'requireFile' "$file" && continue
    grep -q 'fetchFromGitHub\|fetchgit\|fetchurl\|fetchPypi' "$file" || continue
    echo "* ${base}"
    pin_one "$base" "$file"
  done
  echo "Done. Review 'git diff pkgs/' and commit."
}

main "$@"
