#!/usr/bin/env bash
#
# Mint an attic access token on demand. Run on the VPS (it needs the HS256
# secret from /etc/atticd/atticd.env; run with sudo, or export the secret
# yourself). Presets cover the common cases; 'custom' passes the remaining args
# straight through to `atticadm make-token`.
#
# Usage:
#   sudo ./scripts/mint-token.sh reader <name> [validity]    # pull dev + release
#   sudo ./scripts/mint-token.sh ci-dev <name> [validity]    # pull + push dev
#   sudo ./scripts/mint-token.sh ci-rel <name> [validity]    # pull dev, push release
#   sudo ./scripts/mint-token.sh admin  <name> [validity]    # pull/push/create *
#   sudo ./scripts/mint-token.sh custom <name> [validity] -- --pull foo --push bar
#
# <validity> defaults to 90d (e.g. 30d, 6months, 1y). The printed token is a
# bearer credential - hand it over securely and store it as a secret.
set -euo pipefail

_SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ENVFILE="${ATTICD_ENVFILE:-/etc/atticd/atticd.env}"

usage() { sed -n '3,17p' "$0"; exit "${1:-0}"; }
[ "${1:-}" = "-h" ] || [ "${1:-}" = "--help" ] && usage 0

preset="${1:?preset: reader|ci-dev|ci-rel|admin|custom (see -h)}"; shift
name="${1:?token name / subject}"; shift

validity="90d"
if [ "${1:-}" ] && [ "${1:-}" != "--" ]; then validity="$1"; shift; fi

# Load the signing secret unless it is already in the environment.
if [ -z "${ATTIC_SERVER_TOKEN_HS256_SECRET_BASE64:-}" ]; then
  [ -r "$ENVFILE" ] || { echo "cannot read $ENVFILE - run with sudo on the VPS, or set ATTIC_SERVER_TOKEN_HS256_SECRET_BASE64" >&2; exit 1; }
  ATTIC_SERVER_TOKEN_HS256_SECRET_BASE64="$(grep -oP '(?<=HS256_SECRET_BASE64=).*' "$ENVFILE")"
  export ATTIC_SERVER_TOKEN_HS256_SECRET_BASE64
fi

case "$preset" in
  reader) set -- --pull dev --pull release ;;
  ci-dev) set -- --pull dev --push dev ;;
  ci-rel) set -- --pull dev --push release ;;
  admin)  set -- --pull '*' --push '*' --create-cache '*' ;;
  custom) [ "${1:-}" = "--" ] && shift || true ;; # remaining args = raw atticadm flags
  *)      echo "unknown preset: $preset (see -h)" >&2; exit 2 ;;
esac

echo "# token '$name' (${preset}), valid ${validity}:" >&2
atticadm make-token --sub "$name" --validity "$validity" "$@"

# Best-effort usage hint carrying the real domain from settings.nix.
_sf="$_SCRIPT_DIR/../settings.nix"
if [ -r "$_sf" ]; then
  case "$preset" in release|ci-rel) _hk=releaseHost ;; *) _hk=devHost ;; esac
  _host="$(sed -nE "s/^[[:space:]]*$_hk[[:space:]]*=[[:space:]]*\"([^\"]+)\".*/\1/p" "$_sf" | head -1)"
  [ -n "$_host" ] && echo "# use it:  attic login $name https://$_host <token-above>" >&2
fi
