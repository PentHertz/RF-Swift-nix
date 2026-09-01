#!/usr/bin/env bash
#
# Print a fresh /etc/atticd/atticd.env you can install on the VPS. The HS256
# secret is what signs every access token, so treat it like a root credential:
# generate once, store in your password manager, never commit it.
#
# Usage: ./scripts/gen-secrets.sh
set -euo pipefail

command -v openssl >/dev/null || { echo "openssl required" >&2; exit 1; }

cat <<EOF
# ---------------------------------------------------------------------------
# /etc/atticd/atticd.env   (on the VPS: chmod 600, owned by root)
# Keep this OUT of git and out of /nix/store.
# ---------------------------------------------------------------------------
ATTIC_SERVER_TOKEN_HS256_SECRET_BASE64=$(openssl rand 64 | base64 -w0)
AWS_ACCESS_KEY_ID=REPLACE_WITH_OVH_S3_ACCESS_KEY
AWS_SECRET_ACCESS_KEY=REPLACE_WITH_OVH_S3_SECRET_KEY
EOF
