# Maintaining RF-Swift-nix: the short version

Everything a maintainer does day to day, in the order it happens, with the
exact commands. The long explanations live in `docs/` (linked at each step);
this page is the checklist. Run every command from the repository root.

## 0. One-time setup on your machine

The scripts pass `--extra-experimental-features 'nix-command flakes'` to every
`nix` call themselves, so a stock Nix works. For your own `nix ...` commands,
enable the features once instead of typing the flag each time:

```console
mkdir -p ~/.config/nix
echo 'experimental-features = nix-command flakes' >> ~/.config/nix/nix.conf
```

Nothing else is needed on the host: `git`, `jq`, `nix-prefetch-github` and
`nix-update` are fetched from nixpkgs by the scripts (`nix run`). The warning
`Git tree '...' is dirty` only means you have uncommitted changes; ignore it.

## 1. Update the tools (git-pinned packages: `rev` + `hash`)

Every package under `pkgs/` built from a git repository pins an exact commit
(`rev`) and its content hash (`hash`). Updating a tool = moving that pin.

```console
scripts/update-sources.sh                          # report: which pins are behind their branch
scripts/update-sources.sh --write --only tailcat   # re-pin ONE package to the tip of its updateBranch
scripts/update-sources.sh --write                  # re-pin every package that declares updateBranch
```

Packages without an `updateBranch` line are **fixed pins** and are skipped on
purpose (they track a release, or upstream's default branch is not usable).
To move one anyway, name the branch:

```console
scripts/update-sources.sh --write --only NAME --branch main
```

To move a package to a **release tag** instead of a branch tip:

```console
scripts/package-maintenance.sh update NAME                  # newest stable tag (nix-update)
scripts/package-maintenance.sh update NAME --version 1.4.2  # a specific release
```

If you edited `rev` or `version` by hand, or a file still holds
`lib.fakeHash`, recompute only the hash:

```console
scripts/update-sources.sh --refresh-hashes --only NAME   # re-prefetch the pinned rev
scripts/package-maintenance.sh prefetch NAME             # build, read the "got:" hash, write it back
```

Then build what you touched and review the diff:

```console
scripts/package-maintenance.sh check NAME
git diff
```

Details and the vendor-SDK (proprietary download) flow:
[`docs/updating.md`](docs/updating.md), [`docs/adding-packages.md`](docs/adding-packages.md).

## 2. Update the nixpkgs baseline (`flake.lock`)

Everything that comes straight from nixpkgs (GNU Radio, Wireshark, ...) is
versioned by the `nixpkgs` input in `flake.lock`, a separate axis from step 1:

```console
scripts/package-maintenance.sh flake-update            # all inputs
scripts/package-maintenance.sh flake-update nixpkgs    # one input
```

This can break source-built packages (new gcc, new Python). Run the
verification in step 4 before pushing; failure classes and their fixes are in
[`docs/ci-cd.md`](docs/ci-cd.md#diagnosing-failures).

## 3. Regenerate the catalog (only when `environments.nix` changed)

`catalog.json` lists the environments and their tools for the RF Swift CLI and
the Workbench, and it drives the CI build matrix. A package re-pin does **not**
change it; adding or removing a tool in `environments.nix` does:

```console
scripts/package-maintenance.sh catalog
git diff --stat catalog.json     # must never show the file shrinking to nothing
```

CI's `catalog-sync` job fails when the committed file is not what
`environments.nix` generates.

## 4. Verify, commit, push

```console
scripts/package-maintenance.sh check NAME     # each package you changed
./tests/verify.sh                             # evaluation ground truth (all environments)
./tests/smoke-environment.sh rfid             # one environment end to end (optional, slow)
git add -p && git commit && git push
```

Pushing `main` runs CI plus the amd64/arm64 cache builds; riscv64 and darwin
run on `main`, tags and manual dispatch. Successful closures are pushed to the
dev binary cache, so users download instead of compiling
([`docs/binary-cache.md`](docs/binary-cache.md)). A `v*` tag promotes dev to
release.

## 5. What users run to get your update

Nothing on your side. On a user's machine:

```console
rfswift env update <name>        # refresh github:PentHertz/RF-Swift-nix to its tip, rebuild, switch
rfswift env update --check <name>
rfswift env rollback <name>      # the previous closure stays GC-rooted
```

A new environment created right after your push may still see Nix's cached
answer for the branch (one hour); `nix flake metadata --refresh
github:PentHertz/RF-Swift-nix` clears it.

## Reading a red CI run

| Symptom | Meaning | Fix |
|---|---|---|
| Only `prepare` and `report` jobs exist; report fails on `find: 'reports': No such file or directory` | `catalog.json` is empty or has no environments, so the build matrix was empty | `scripts/package-maintenance.sh catalog`, commit. The prepare step now fails with a clear error instead. |
| `build (<env>)` red, `report` green with a table | a real build failure in that environment | open the job, find the first failed `.drv`; classes in [`docs/ci-cd.md`](docs/ci-cd.md#diagnosing-failures) |
| Almost every Linux `build (<env>)` red within a minute or two, the only failed `.drv` is `rfswift-<env>.drv` itself, macOS green | the environment's `buildEnv` step failed, not a tool: everything was fetched from the cache and the final merge broke (last seen with a `postBuild` writing into `share/rfswift`, a directory `buildEnv` links straight into `rfswift-gl`'s store path when no second package provides it) | read the "Failure context" block of the summary (Nix's own last log lines); reproduce with `nix build .#packages.x86_64-linux.<env>`, which only needs the cache, not a rebuild |
| `catalog-sync` red | committed `catalog.json` differs from `environments.nix` | step 3 |
| `attic login`/push red, builds green | cache token expired or wrong host | [`docs/ci-cd.md`](docs/ci-cd.md#self-hosted-attic-cache-dev--release) |
| "Node.js 20 is deprecated" at the end of a job | informational; an action still on an old major | pin the action to its current release by commit (see the workflows for the format) |

## Traps that have bitten us

- **Empty `catalog.json` committed.** The catalog app used to redirect
  `nix eval` straight into the file, so a failed eval truncated it to 0 bytes
  and `git add catalog.json` shipped that. It now writes to a temporary file
  first. If it ever happens again: `git checkout <last good commit> -- catalog.json`.
- **`rg: command not found`.** `update-sources.sh` needed ripgrep; it uses
  `grep` now. Nothing to install.
- **`experimental Nix feature 'nix-command' is disabled`.** A `nix` call
  without the flags: either enable the features (step 0) or use the script
  wrappers, which always pass them. Never a reason to `sudo` anything.
- **`--write` says "unchanged" for a package `check` reported as behind.** A
  previous `--write` already moved it; look at `git status`.
- **Writing into `$out` from `buildEnv`'s `postBuild`.** `buildEnv` links a
  directory that a single package provides straight into that package's store
  path (read-only); only when two packages provide it does it become a real
  directory. Anything the environment must ship goes in as a package of its
  own (`writeTextFile` with a `destination`), merged like the tools.
- **`error: Cannot build '<drv>'.`** is how Nix 2.30+ (install-nix-action v31)
  words what used to be `error: builder for '<drv>' failed`. The cause is on
  the indented `Reason:` line below it, followed by the builder's last log
  lines; a `Reason: N dependencies failed` entry is only the parent of the
  real failure, look for the other `Cannot build` line.
- **`update` (nix-update) succeeds but the build breaks.** Version bumps can
  need new dependencies or patches; `git diff` the package, read the build log,
  compare with upstream's release notes.
