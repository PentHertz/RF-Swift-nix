#!/usr/bin/env bash
#
# Push store paths (and their closure) to the dev or release cache. Meant to run
# in GitHub Actions after a build, using a scoped push token. The endpoint is
# taken from settings.nix, so CI only needs to provide the token.
#
# Env:
#   ATTIC_TOKEN      a pull+push token for that cache (GitHub secret)
#   ATTIC_ENDPOINT   optional override; default derived from settings.nix
#
# Usage:
#   ./scripts/push-to-cache.sh <dev|release> <store-path|installable> [more...]
#
# Example (build then push the reversing env + closure to dev):
#   out=$(nix build .#packages.x86_64-linux.reversing --print-out-paths)
#   ATTIC_TOKEN=$TOK ./scripts/push-to-cache.sh dev "$out"
set -euo pipefail
# shellcheck source=lib.sh
. "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

target="${1:?usage: push-to-cache.sh <dev|release> <paths...>}"; shift
: "${ATTIC_TOKEN:?set ATTIC_TOKEN}"
[ "$#" -ge 1 ] || { echo "no paths given" >&2; exit 2; }

case "$target" in
  dev)     cache="$DEV_CACHE";     : "${ATTIC_ENDPOINT:=https://$DEV_HOST}" ;;
  release) cache="$RELEASE_CACHE"; : "${ATTIC_ENDPOINT:=https://$RELEASE_HOST}" ;;
  *) echo "target must be 'dev' or 'release'" >&2; exit 2 ;;
esac

# Non-interactive login writes a token into attic's client config for this run.
attic login ci "$ATTIC_ENDPOINT" "$ATTIC_TOKEN"

# attic push uploads each path plus its runtime closure, dedup-chunked to S3.
attic push "$cache" "$@"

echo "pushed to $cache ($ATTIC_ENDPOINT): $*"
