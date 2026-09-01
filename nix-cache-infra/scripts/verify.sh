#!/usr/bin/env bash
#
# Health-check the whole cache chain. Run on the VPS. Reads hostnames/cache
# names from settings.nix. Optional env:
#   READER_TOKEN   a pull token -> enables the authenticated 200 check
#   ORIGIN_IP      IP to force via curl --resolve (default 127.0.0.1, i.e. the
#                  local origin, so it works even before public DNS propagates)
#
# Usage:  READER_TOKEN=eyJ... ./scripts/verify.sh
set -uo pipefail
# shellcheck source=lib.sh
. "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

ORIGIN_IP="${ORIGIN_IP:-127.0.0.1}"
RC=0
ok()   { printf '  \033[32mOK\033[0m   %s\n' "$*"; }
bad()  { printf '  \033[31mFAIL\033[0m %s\n' "$*"; RC=1; }
note() { printf '  ..   %s\n' "$*"; }

# 1. atticd listening on loopback
echo "atticd:"
if ss -ltn 2>/dev/null | grep -q '127.0.0.1:8080'; then ok "listening on 127.0.0.1:8080"
else bad "not listening on 127.0.0.1:8080 (check: journalctl -u atticd)"; fi

# 2. caddy active
echo "caddy:"
if systemctl is-active --quiet caddy; then ok "service active"
else bad "service not active"; fi

# 3. origin reachable over TLS per cache: unauth -> 401, auth (if token) -> 200
check_host() {
  local host="$1" cache="$2"
  echo "origin https://$host/$cache:"
  local code
  code=$(curl -s -o /dev/null -w '%{http_code}' --resolve "$host:443:$ORIGIN_IP" \
           "https://$host/$cache/nix-cache-info" 2>/dev/null)
  case "$code" in
    401) ok  "unauthenticated -> 401 (private cache, TLS+atticd OK)";;
    200) note "unauthenticated -> 200 (cache is PUBLIC - expected private?)";;
    000) bad "no TLS response (cert or Caddy problem)";;
    *)   bad "unexpected status $code";;
  esac
  if [ -n "${READER_TOKEN:-}" ]; then
    code=$(curl -s -o /dev/null -w '%{http_code}' --resolve "$host:443:$ORIGIN_IP" \
             -H "Authorization: Bearer $READER_TOKEN" \
             "https://$host/$cache/nix-cache-info" 2>/dev/null)
    [ "$code" = "200" ] && ok "authenticated -> 200" || bad "authenticated -> $code (token/scope?)"
  fi
}
check_host "$RELEASE_HOST" "$RELEASE_CACHE"
check_host "$DEV_HOST" "$DEV_CACHE"

echo
[ "$RC" -eq 0 ] && echo "All checks passed." || echo "Some checks FAILED (see above)."
exit "$RC"
