# Updating tools and refreshing hashes

> New contributors should use the unified workflow in
> [`adding-packages.md`](adding-packages.md). The lower-level commands below are
> retained for bulk branch-pin maintenance and troubleshooting.
> The one-page checklist of the whole maintenance cycle is
> [`../MAINTAINING.md`](../MAINTAINING.md).

RF Swift's Nix packages pin their sources for reproducibility, so updating a tool
means moving a pin forward and re-pinning its content hash. There are two axes.

## 1. Per-package source pins (the tools themselves)

Every package under `pkgs/` that builds from git pins an exact `rev` + `hash` in a
`fetchFromGitHub { owner; repo; rev; hash; }` block. Use `scripts/update-sources.sh`
to inspect and refresh these.

```bash
# See which git-pinned packages have a newer upstream commit (report only):
./scripts/update-sources.sh

# Re-pin one package to the latest commit of its branch (rev + hash rewritten):
./scripts/update-sources.sh --only gr-lora --write

# Re-pin every git-pinned package:
./scripts/update-sources.sh --write

# Repair a stale/placeholder hash WITHOUT changing the revision:
./scripts/update-sources.sh --refresh-hashes --only gr-dsd

# Track a specific branch instead of the default:
./scripts/update-sources.sh --only gr-droneid --branch gr-droneid-update-3.10 --write
```

After `--write`, build the affected packages and commit:

```bash
nix build .#pkg-gr-lora --no-link      # confirm it still builds
git add pkgs/ && git commit -m "gr-lora: bump to latest upstream"
```

Manual re-pin (what the script automates), if you ever need it: set the `hash` to
`lib.fakeHash`, run `nix build .#pkg-<name>`, and paste the `got:` hash Nix prints.

### Bumping one tool's version (and its hashes)

For a single package, `scripts/package-maintenance.sh` drives the whole update:

```bash
# Version bump: nix-update rewrites version + src hash (+ vendorHash/cargoHash):
./scripts/package-maintenance.sh update <name> --version 1.4.2

# Branch/commit package: edit `rev` (and `version`) in pkgs/**/<name>.nix, then:
./scripts/package-maintenance.sh prefetch <name>   # pins every stale hash

# Confirm and (re)pin any hash that is still wrong:
./scripts/package-maintenance.sh check <name>
```

### Secondary hashes (Go `vendorHash`, Rust `cargoHash`)

A Go (`buildGoModule`) or Rust (`buildRustPackage`) tool has a **second** hash for
its fetched dependencies (`vendorHash` / `cargoHash`) on top of the `src` hash.
When you move the version or `rev`, both must change. `prefetch` handles this: it
re-runs the build and pins each `got:` mismatch in turn (source first, then the
vendor/cargo hash), up to four passes. Never paste the `specified:` value — only
the `got:` one. To do it by hand, set the offending hash to `lib.fakeHash` and
rebuild once per hash.

## Vendor SDK downloads (proprietary blobs)

Commercial SDKs (SignalHound, Harogic, Deepace KC908, SAStudio, ...) are not git
pins - their version, download URL and content hash live in
`pkgs/vendor/sources.json`. Update them with the `vendor-update` subcommand, which
prefetches the archive and rewrites version + url + hash (and per-system
`artifacts` for SDKs that ship one download per platform):

```bash
# See current versions and (optionally) probe upstream for newer ones:
./scripts/package-maintenance.sh vendor-report [--check-urls]

# Single-download SDK:
./scripts/package-maintenance.sh vendor-update signalhound-sdk 08_26_26 \
  https://signalhound.com/sigdownloads/SDK/signal_hound_sdk_08_26_26.zip

# Per-system SDK (repeat once per platform it ships):
./scripts/package-maintenance.sh vendor-update sastudio 4.4.55.48 \
  https://.../SAStudio4_4.4.55.48_arm64.zip --system aarch64-linux

./scripts/package-maintenance.sh check <name>   # then verify it still builds
```

## 2. The nixpkgs baseline (everything from nixpkgs)

Tools pulled straight from nixpkgs move when the flake input moves:

```bash
nix flake update                 # bump all inputs (nixpkgs, nixpkgs-py310)
nix flake update nixpkgs         # bump only nixpkgs
git add flake.lock && git commit -m "flake: bump nixpkgs"
```

## 3. Verify after any update

```bash
./tests/verify.sh                        # eval gate: catalog + every env + every pkg-*
./tests/smoke-environment.sh <env>       # build + command check for a touched env
./scripts/security-audit.sh --env <env>  # CVE / supply-chain / integrity check
```

`security-audit.sh` is also how you find out whether an update pulled in (or fixed)
a known vulnerability, so run it after a nixpkgs bump.

## GNU Radio OOT modules

The OOT set is generated from `RF-Swift-images/scripts/gr_oot_modules.sh` (the
Docker reference). To add or move one, edit its `pkgs/oot/gr-*.nix` (or add a new
file following the existing pattern), wire it in `pkgs/default.nix` and
`pkgs/gnuradio-rfswift.nix`, then `update-sources.sh --only <name> --write` to
pin it and `nix build .#pkg-<name>` to verify.
