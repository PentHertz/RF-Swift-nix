#!/usr/bin/env bash
#
# update-sources.sh - refresh the pinned source revisions/hashes of RF Swift's
# own packages, so the bundled tools can be updated to newer upstream commits.
#
# Every package under pkgs/ that builds from a git source pins an exact
# `rev` + `hash` in a `fetchFromGitHub { owner; repo; rev; hash; }` block (this
# is what makes the build reproducible). Updating a tool therefore means moving
# that pin forward and re-pinning the content hash. This script automates both.
#
# Two axes of "update":
#   * This script updates the PER-PACKAGE source pins (the tools themselves).
#   * `nix flake update` updates the flake INPUTS (nixpkgs), i.e. the versions of
#     everything pulled straight from nixpkgs. Run that separately when you want
#     to move the nixpkgs baseline.
#
# Modes:
#   (default)         check only: for each git-pinned package, show the pinned rev
#                     and whether a newer commit exists on its tracked branch.
#   --write           apply updates: re-pin each selected package to the latest
#                     commit of its branch (rev + hash rewritten in the .nix).
#   --refresh-hashes  do not move the rev; only recompute the hash for the
#                     currently pinned rev (repairs a stale/placeholder hash).
#
# Selection:
#   --only NAME       restrict to pkgs/**/NAME.nix (repeatable)
#   --branch REF      use REF instead of each repo's default branch (with --write)
#
# Examples:
#   scripts/update-sources.sh                       # what could be updated
#   scripts/update-sources.sh --only gr-lora --write
#   scripts/update-sources.sh --write               # bump every git-pinned package
#   scripts/update-sources.sh --refresh-hashes --only gr-dsd

set -uo pipefail

repo=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
cd "$repo" || { echo "error: cannot cd to repo root" >&2; exit 2; }

nix=(nix --extra-experimental-features "nix-command flakes")
run_tool() { "${nix[@]}" run --inputs-from . "nixpkgs#$1" -- "${@:2}"; }

mode="check"; branch=""; declare -a only=()
while [[ $# -gt 0 ]]; do
  case "$1" in
    --write)          mode="write"; shift ;;
    --refresh-hashes) mode="refresh"; shift ;;
    --only)           only+=("$2"); shift 2 ;;
    --branch)         branch="$2"; shift 2 ;;
    -h|--help)        awk 'NR>=3{ if(/^set -uo pipefail/)exit; sub(/^# ?/,""); print }' "${BASH_SOURCE[0]}"; exit 0 ;;
    *)                echo "unknown argument: $1" >&2; exit 2 ;;
  esac
done

# ANSI colour only on a terminal.
c() { [[ -t 1 ]] && printf '%b' "$1" || true; }
G=$'\e[32m'; Y=$'\e[33m'; R=$'\e[31m'; Z=$'\e[0m'

# Extract "owner repo rev hash" from the (first) fetchFromGitHub block in a file.
# Portable: grep the first of each field rather than relying on gawk extensions.
field() { grep -m1 -oE "$2[[:space:]]*=[[:space:]]*\"[^\"]*\"" "$1" | sed -E 's/.*"([^"]*)".*/\1/'; }
extract() {
  local f="$1"
  local owner repo rev hash
  owner=$(field "$f" owner); repo=$(field "$f" repo)
  rev=$(field "$f" rev);     hash=$(field "$f" hash)
  [[ -n "$owner" && -n "$repo" ]] && printf '%s %s %s %s\n' "$owner" "$repo" "$rev" "$hash"
}

# Gather target files: those under pkgs/ with a fetchFromGitHub source.
mapfile -t files < <(grep -rl "fetchFromGitHub" pkgs/ 2>/dev/null | sort)
if [[ ${#only[@]} -gt 0 ]]; then
  sel=()
  for f in "${files[@]}"; do
    base=$(basename "$f" .nix)
    for o in "${only[@]}"; do [[ "$base" == "$o" ]] && sel+=("$f"); done
  done
  files=("${sel[@]}")
fi
[[ ${#files[@]} -eq 0 ]] && { echo "no matching git-pinned package files"; exit 0; }

echo "RF Swift source update ($mode) over ${#files[@]} package file(s)"
updated=0; checked=0

for f in "${files[@]}"; do
  read -r owner reponame rev hash < <(extract "$f")
  [[ -z "${owner:-}" || -z "${reponame:-}" ]] && continue
  checked=$((checked+1))
  name=$(basename "$f" .nix)
  url="https://github.com/${owner}/${reponame}.git"

  case "$mode" in
    check)
      # Latest commit on the tracked ref (branch override, else default HEAD).
      ref="HEAD"; [[ -n "$branch" ]] && ref="refs/heads/$branch"
      latest=$(run_tool git ls-remote "$url" "$ref" 2>/dev/null | awk '{print $1; exit}')
      if [[ -z "$latest" ]]; then
        printf '  %-26s %s? cannot reach %s/%s%s\n' "$name" "$(c "$Y")" "$owner" "$reponame" "$(c "$Z")"
      elif [[ "$latest" == "$rev" ]]; then
        printf '  %-26s %sok up to date%s (%.12s)\n' "$name" "$(c "$G")" "$(c "$Z")" "$rev"
      else
        printf '  %-26s %sUPDATE%s %.12s -> %.12s\n' "$name" "$(c "$Y")" "$(c "$Z")" "$rev" "$latest"
        updated=$((updated+1))
      fi
      ;;
    write|refresh)
      local_args=(--quiet)
      if [[ "$mode" == "refresh" ]]; then
        local_args+=(--rev "$rev")
      elif [[ -n "$branch" ]]; then
        local_args+=(--rev "refs/heads/$branch")
      fi
      out=$(run_tool nix-prefetch-git "${local_args[@]}" "$url" 2>/dev/null)
      newrev=$(echo "$out" | jq -r '.rev // empty' 2>/dev/null)
      newhash=$(echo "$out" | jq -r '.hash // empty' 2>/dev/null)
      if [[ -z "$newrev" || -z "$newhash" ]]; then
        printf '  %-26s %sFAILED to prefetch%s\n' "$name" "$(c "$R")" "$(c "$Z")"; continue
      fi
      if [[ "$newrev" == "$rev" && "$newhash" == "$hash" ]]; then
        printf '  %-26s %sunchanged%s\n' "$name" "$(c "$G")" "$(c "$Z")"; continue
      fi
      # Rewrite the rev and hash lines of this file's fetchFromGitHub block.
      sed -i -E "s|(rev[[:space:]]*=[[:space:]]*)\"[^\"]*\"|\1\"${newrev}\"|" "$f"
      sed -i -E "s|(hash[[:space:]]*=[[:space:]]*)\"[^\"]*\"|\1\"${newhash}\"|" "$f"
      printf '  %-26s %sre-pinned%s %.12s -> %.12s\n' "$name" "$(c "$Y")" "$(c "$Z")" "$rev" "$newrev"
      updated=$((updated+1))
      ;;
  esac
done

echo ""
case "$mode" in
  check)   echo "$checked package(s) checked, $updated with a newer commit available. Re-run with --write to bump." ;;
  write)   echo "$updated package(s) re-pinned. Build them (nix build .#pkg-<name>) and commit the changes." ;;
  refresh) echo "$updated package hash(es) refreshed." ;;
esac
