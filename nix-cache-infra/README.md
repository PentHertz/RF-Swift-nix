# nix-cache-infra

Hardened, S3-backed Nix binary cache for RF-Swift CI/CD, with a **dev** cache and
a promoted **release** cache, on a tiny OVH VPS managed entirely with Nix
(`system-manager`, since OVH has no NixOS image).

- NARs live in **OVH Object Storage (S3)** - the VPS stays tiny.
- **attic** serves the cache (tokens, signing, dedup, GC), **Caddy** does TLS.
- Locked down for GitHub-hosted CI (no VPN): token-over-TLS only, SSH admin-only,
  private caches, sandboxed services, `zram` for headroom.

**Start here: [SETUP.md](./SETUP.md)** - architecture, security model, step-by-step
deploy, and GitHub Actions integration (with diagrams).

```
settings.nix   edit first: hosts, S3, admin CIDRs + keys (single source of truth)
flake.nix      system-manager entrypoint
modules/       attic, caddy, hardening, zram
scripts/       bootstrap, gen-secrets, mint-token, use-cache, push-to-cache, promote
               (CI scripts read the domain from settings.nix - you pass only a token)
```

Tokens: a pull+push token for CI (`mint-token.sh ci-dev`), a promote token
(`ci-rel`), and pull-only tokens for consumers (`reader`). Generate more anytime
with `scripts/mint-token.sh`.

Quick deploy: edit `settings.nix`, then on a fresh Debian/Ubuntu VPS run
`sudo ./scripts/bootstrap.sh`.
