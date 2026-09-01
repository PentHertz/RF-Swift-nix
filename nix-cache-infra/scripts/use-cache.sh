#!/usr/bin/env bash
#
# Enable a cache as a Nix substituter (the PULL side) using a token. Run this
# before `nix build` in CI so the build reuses already-cached paths. Endpoint is
# taken from settings.nix; you only supply the token.
#
# Env:
#   ATTIC_TOKEN      a token with pull rights on that cache
#   ATTIC_ENDPOINT   optional override; default derived from settings.nix
#
# Usage:
#   ATTIC_TOKEN=$TOK ./scripts/use-cache.sh <dev|release>
set -euo pipefail
# shellcheck source=lib.sh
. "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

target="${1:?usage: use-cache.sh <dev|release>}"
: "${ATTIC_TOKEN:?set ATTIC_TOKEN}"

case "$target" in
  dev)     cache="$DEV_CACHE";     : "${ATTIC_ENDPOINT:=https://$DEV_HOST}" ;;
  release) cache="$RELEASE_CACHE"; : "${ATTIC_ENDPOINT:=https://$RELEASE_HOST}" ;;
  *) echo "target must be 'dev' or 'release'" >&2; exit 2 ;;
esac

attic login ci "$ATTIC_ENDPOINT" "$ATTIC_TOKEN"
# Wires the cache into nix.conf as a trusted substituter for this machine.
attic use "$cache"

echo "using $cache ($ATTIC_ENDPOINT) as a substituter"
