#!/usr/bin/env bash
#
# Promote a closure from the dev cache to the release ("final") cache. Runs on a
# release tag: it pulls each path from dev into the local store (verifying
# signatures), then pushes it to release, where attic re-signs it. Endpoints are
# taken from settings.nix; CI only supplies the token and the dev public key.
#
# Env:
#   ATTIC_TOKEN        a release push token (GitHub secret)
#   DEV_PUBLIC_KEY     the dev cache public key (dev:BASE64...)
#   DEV_SUBSTITUTER    optional override; default https://<devHost>/<devCache>
#   ATTIC_ENDPOINT     optional override; default https://<releaseHost>
#
# Usage:
#   ./scripts/promote.sh <store-path> [more...]
set -euo pipefail
# shellcheck source=lib.sh
. "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

: "${ATTIC_TOKEN:?set ATTIC_TOKEN}"
: "${DEV_PUBLIC_KEY:?set DEV_PUBLIC_KEY (from: attic cache info dev)}"
: "${DEV_SUBSTITUTER:=$DEV_URL}"
: "${ATTIC_ENDPOINT:=https://$RELEASE_HOST}"
[ "$#" -ge 1 ] || { echo "usage: promote.sh <store-paths...>" >&2; exit 2; }

# 1. Bring the exact paths from dev into the local store (signature-checked).
nix copy \
  --from "$DEV_SUBSTITUTER" \
  --option trusted-public-keys "$DEV_PUBLIC_KEY" \
  "$@"

# 2. Publish to the release cache.
attic login ci "$ATTIC_ENDPOINT" "$ATTIC_TOKEN"
attic push "$RELEASE_CACHE" "$@"

echo "promoted to $RELEASE_CACHE ($ATTIC_ENDPOINT): $*"
