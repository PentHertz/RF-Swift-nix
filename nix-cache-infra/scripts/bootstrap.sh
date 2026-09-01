#!/usr/bin/env bash
#
# Provision a fresh OVH VPS (Debian 12+ / Ubuntu 22.04+) as the RF-Swift Nix
# binary cache: create the admin user, install Nix, apply the hardened
# system-manager configuration, and enable OS security updates.
#
# Run as root on the VPS, from the repo root:
#     sudo ./scripts/bootstrap.sh
#
# It is idempotent - safe to re-run after editing settings.nix.
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_DIR"

log() { printf '\033[1;32m[bootstrap]\033[0m %s\n' "$*"; }
die() { printf '\033[1;31m[bootstrap] %s\033[0m\n' "$*" >&2; exit 1; }

[ "$(id -u)" -eq 0 ] || die "run as root"

# --- read a couple of values out of settings.nix without needing Nix yet ------
admin_user="$(sed -nE 's/^\s*adminUser\s*=\s*"([^"]+)".*/\1/p' settings.nix | head -1)"
[ -n "$admin_user" ] || die "could not read adminUser from settings.nix"

# --- 1. base packages --------------------------------------------------------
log "installing base packages"
export DEBIAN_FRONTEND=noninteractive
apt-get update -y
apt-get install -y --no-install-recommends \
  curl xz-utils git ca-certificates sudo unattended-upgrades openssl

# --- 2. admin user + SSH keys (BEFORE root SSH is disabled) -------------------
if ! id "$admin_user" >/dev/null 2>&1; then
  log "creating admin user '$admin_user'"
  adduser --disabled-password --gecos "" "$admin_user"
  usermod -aG sudo "$admin_user"
fi
install -d -m 700 -o "$admin_user" -g "$admin_user" "/home/$admin_user/.ssh"
# Pull the admin public keys out of settings.nix into authorized_keys.
sed -nE 's/^\s*"(ssh-[^"]+)".*/\1/p' settings.nix > "/home/$admin_user/.ssh/authorized_keys"
chown "$admin_user:$admin_user" "/home/$admin_user/.ssh/authorized_keys"
chmod 600 "/home/$admin_user/.ssh/authorized_keys"
if ! [ -s "/home/$admin_user/.ssh/authorized_keys" ]; then
  die "no adminSSHKeys in settings.nix - add your public key or you WILL be locked out"
fi
# Passwordless sudo for the deploy user (needed for later 'system-manager switch').
echo "$admin_user ALL=(ALL) NOPASSWD:ALL" > "/etc/sudoers.d/90-$admin_user"
chmod 440 "/etc/sudoers.d/90-$admin_user"

# --- 3. secret scaffolding (filled in by you, never in git/store) ------------
if [ ! -f /etc/atticd/atticd.env ]; then
  log "creating /etc/atticd/atticd.env template (fill in the S3 keys!)"
  install -d -m 700 /etc/atticd
  umask 077
  cat > /etc/atticd/atticd.env <<EOF
# Filled by the operator. chmod 600, root-only. NOT in git, NOT in /nix/store.
ATTIC_SERVER_TOKEN_HS256_SECRET_BASE64=$(openssl rand 64 | base64 -w0)
AWS_ACCESS_KEY_ID=REPLACE_WITH_OVH_S3_ACCESS_KEY
AWS_SECRET_ACCESS_KEY=REPLACE_WITH_OVH_S3_SECRET_KEY
EOF
  chmod 600 /etc/atticd/atticd.env
else
  log "/etc/atticd/atticd.env already present - leaving it untouched"
fi

# --- 4. Nix (Determinate installer: flakes on, works on non-NixOS) -----------
if ! command -v nix >/dev/null 2>&1; then
  log "installing Nix"
  curl -fsSL https://install.determinate.systems/nix | \
    sh -s -- install --no-confirm
fi
# shellcheck disable=SC1091
. /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh 2>/dev/null || true

# --- 5. OS auto security updates (base OS is apt, not Nix) --------------------
log "enabling unattended-upgrades"
dpkg-reconfigure -f noninteractive unattended-upgrades || true
systemctl enable --now unattended-upgrades || true

# --- 6. apply the declarative, hardened configuration ------------------------
log "applying system-manager configuration"
nix run 'github:numtide/system-manager' -- switch --flake ".#default"

# --- 7. reload sshd so the hardening drop-in takes effect ---------------------
systemctl reload ssh 2>/dev/null || systemctl reload sshd 2>/dev/null || true

log "done."
cat <<EOF

Next steps:
  1. Put real OVH S3 keys in /etc/atticd/atticd.env, then:  systemctl restart atticd
  2. Confirm DNS A/AAAA for the two hostnames point here (Caddy needs it for TLS).
  3. Create the caches + mint tokens:  see SETUP.md 'Create caches and tokens'.
  4. Verify from a client:  nix store info --store https://<releaseHost>/<release-cache>
  5. Log in as '$admin_user' over SSH and confirm before closing this root session.
EOF
