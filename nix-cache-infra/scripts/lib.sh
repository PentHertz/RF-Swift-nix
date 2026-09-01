# Shared helper: read the deployment's real hostnames and cache names out of
# settings.nix so every script "carries the domain" from one source of truth.
# Sourced by the other scripts. Override the file with SETTINGS_FILE=... .

_SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SETTINGS_FILE="${SETTINGS_FILE:-$_SCRIPT_DIR/../settings.nix}"

[ -r "$SETTINGS_FILE" ] || { echo "settings.nix not found at $SETTINGS_FILE (set SETTINGS_FILE)" >&2; exit 1; }

# _setting <attr> : print the string value of a top-level `attr = "...";`
_setting() { sed -nE "s/^[[:space:]]*$1[[:space:]]*=[[:space:]]*\"([^\"]+)\".*/\1/p" "$SETTINGS_FILE" | head -1; }

DEV_HOST="$(_setting devHost)"
RELEASE_HOST="$(_setting releaseHost)"

# Cache names come from the `caches = { dev = "..."; release = "..."; }` block.
_caches_block="$(sed -nE '/caches[[:space:]]*=[[:space:]]*\{/,/\}/p' "$SETTINGS_FILE")"
DEV_CACHE="$(printf '%s' "$_caches_block" | sed -nE 's/.*\bdev[[:space:]]*=[[:space:]]*"([^"]+)".*/\1/p' | head -1)"
RELEASE_CACHE="$(printf '%s' "$_caches_block" | sed -nE 's/.*\brelease[[:space:]]*=[[:space:]]*"([^"]+)".*/\1/p' | head -1)"

# Sensible fallbacks if the block was renamed.
DEV_CACHE="${DEV_CACHE:-dev}"
RELEASE_CACHE="${RELEASE_CACHE:-release}"

[ -n "$DEV_HOST" ] && [ -n "$RELEASE_HOST" ] || { echo "could not read devHost/releaseHost from $SETTINGS_FILE" >&2; exit 1; }

# Full substituter URLs (host + cache path).
DEV_URL="https://$DEV_HOST/$DEV_CACHE"
RELEASE_URL="https://$RELEASE_HOST/$RELEASE_CACHE"
