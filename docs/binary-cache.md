# Using the PentHertz binary cache

RF Swift Nix environments are prebuilt by CI and published to a self-hosted
binary cache. Once your machine is pointed at it, `nix build`, `nix develop`
and `rfswift run --engine nix` download the tools instead of compiling them.

| Cache | URL | What it holds |
|---|---|---|
| `release` | `https://nixcache.penthertz.com/release` | Closures promoted on every `v*` tag. Use this on a normal machine. |
| `dev` | `https://nixcache-dev.penthertz.com/dev` | Everything CI builds on every branch push, including work in progress. Add it if you develop RF-Swift-nix itself. |

Both caches are private: reads need a token. `cache.nixos.org` still serves
everything that is plain nixpkgs; the PentHertz cache adds RF Swift's own
derivations (`pkgs/`) and the assembled environments.

The server side (attic on a VPS, S3 storage, token minting) is documented in
[`nix-cache-infra/SETUP.md`](../nix-cache-infra/SETUP.md). This page is the
client side only.

## 1. Get a reader token

Tokens are minted on the cache server by an admin:

```bash
sudo ./scripts/mint-token.sh reader <who> 1y      # pull dev + release, valid one year
```

The printed token is the only secret you need. Treat it like a password.
You also need the public key of each cache you enable, shown by
`attic cache info release` / `attic cache info dev` on the server. The release
key is:

```
release:d8owbIehqU52DRGRfhfx1/ykhRiCYgk5QKUh4lWPPBk=
```

## 2. Configure Nix

Nix runs builds through a daemon on most installs (Linux multi-user and macOS).
The daemon only honours substituters coming from your own `~/.config/nix/nix.conf`
if your user is listed in `trusted-users`, which is not the default. The
system-wide file works everywhere, so start there.

### Option A: system-wide `nix.conf` (recommended)

Append to `/etc/nix/nix.conf`:

```
experimental-features = nix-command flakes
extra-substituters = https://nixcache.penthertz.com/release
extra-trusted-public-keys = release:d8owbIehqU52DRGRfhfx1/ykhRiCYgk5QKUh4lWPPBk=
```

To also pull CI's in-progress builds, add the dev URL and key on the same two
lines:

```
extra-substituters = https://nixcache.penthertz.com/release https://nixcache-dev.penthertz.com/dev
extra-trusted-public-keys = release:d8owbIehqU52DRGRfhfx1/ykhRiCYgk5QKUh4lWPPBk= dev:<key from attic cache info dev>
```

Put the token in `/etc/nix/netrc` (Nix reads this path by default; keep it
root-owned, mode 600), one block per host you enabled:

```
machine nixcache.penthertz.com
password <reader-token>
machine nixcache-dev.penthertz.com
password <reader-token>
```

Restart the daemon so it picks the settings up:

```bash
sudo systemctl restart nix-daemon                              # Linux
sudo launchctl kickstart -k system/org.nixos.nix-daemon        # macOS
```

### Option B: the attic client

`attic use` writes the substituter, public key and netrc entry for you, into
your user configuration. It needs your user in `trusted-users`
(`trusted-users = root <you>` in `/etc/nix/nix.conf`, then restart the daemon).

```bash
nix profile install nixpkgs#attic-client
attic login penthertz https://nixcache.penthertz.com <reader-token>
attic use release
attic use dev          # optional
```

## 3. Check it works

Ask the cache directly for an environment closure:

```bash
nix path-info --store https://nixcache.penthertz.com/release \
  "$(nix eval --raw github:PentHertz/RF-Swift-nix#packages.x86_64-linux.network)"
```

A store path printed back means the cache serves it (a 401 means the token is
missing or wrong for that host). Then a real build should be all downloads:

```bash
nix build github:PentHertz/RF-Swift-nix#network --dry-run
```

Everything should be listed under "will be fetched"; anything under "will be
built" is either not cached for your architecture yet or newer than the last
CI run. Cached architectures are `x86_64-linux`, `aarch64-linux`,
`riscv64-linux` and `aarch64-darwin` (Apple Silicon). Intel macOS builds from
source.

## Troubleshooting

- **`warning: ignoring untrusted substituter`**: the settings are in your user
  config but your user is not in `trusted-users`. Move them to
  `/etc/nix/nix.conf` (Option A) or add yourself to `trusted-users`.
- **`HTTP error 401`**: no token reached the cache. Check the `machine` line in
  `/etc/nix/netrc` matches the host exactly, and that the file is readable by
  the daemon (root).
- **Paths still compile**: run the `--dry-run` above. If the environment is in
  "will be built", the cache does not have it for your system yet; the CI
  reports (`docs/ci-cd.md`) show what built last.
- **Token expired**: tokens carry a validity (one year in the example). Mint a
  new one and replace the password in the netrc file. No restart is needed for
  netrc changes.
