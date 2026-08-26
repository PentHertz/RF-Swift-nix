# RF Swift's own Nix packages

This directory holds the derivations RF Swift needs that are not (or not in the
right fork) in nixpkgs. `default.nix` returns the whole set; `flake.nix` merges
it in so environments can reference these names directly, and it takes priority
over a nixpkgs attribute of the same name.

Three kinds of packages live here.

## 1. Source builds

Plain `stdenv.mkDerivation` / cmake / make derivations for tools that are only
distributed as source: `readsb`, `dumpvdl2`, `dumphfdl`, `libacars`,
`retrogram-soapysdr`, `gqrx-scanner`.

## 2. Fork overrides

RF Swift ships PentHertz / HydraSDR forks of some upstreams. We do not rewrite
their build; we take the nixpkgs derivation and swap its `src`:
`gr-osmosdr-penthertz`, `inspectrum-hydrasdr`, `sdrpp-hydrasdr`,
`luaradio-hydrasdr`, and `urh-ng`. Note `urh-ng` is compiled from source (the
Docker image uses a prebuilt `.deb`, but URH is a normal Python/Cython app, so
there is no reason to ship the binary).

## 3. Proprietary vendor binaries

Closed SDKs still work in Nix. `vendor/mkVendorBinary.nix` unpacks the vendor
artifact, runs `autoPatchelfHook` to point each ELF at Nix-store libraries, and
installs it. See `vendor/default.nix` for `signalhound-sdk` and
`harogic-htra-sdk`.

Two ways to get the artifact into the store:

- **Public URL:** `src = fetchurl { url = "..."; hash = "..."; };`
- **Behind a EULA/login:** `src = requireFile { name = "..."; hash = "..."; message = "..."; };`
  The user downloads it once, runs `nix-store --add-fixed sha256 <file>`, and
  Nix uses it from the store by hash from then on.

`allowUnfree = true` is set in `flake.nix`, so unfree licenses build without extra flags.

## Updating hashes (now and later)

A Nix source hash is the content hash of the fetched source. Pinning the initial
`lib.fakeHash` placeholders and updating a hash after you bump a package are the
same operation: fetch the source and record what came back.

### One command

```
bash pkgs/update.sh            # refresh every source hash that needs it
bash pkgs/update.sh readsb     # just one package
```

For each `pkgs/<name>.nix` it builds `.#pkg-<name>`; Nix fetches the source and,
if the recorded hash is wrong, reports the correct one, which the script writes
back. Review `git diff pkgs/` and commit. It skips the vendor blobs.

### By hand (one package)

```
nix build .#pkg-readsb        # fails with a hash mismatch; copy the "got:" value
```

Paste that into the derivation's `hash =` and rebuild. This is all `update.sh`
automates.

### With the ecosystem tools

- Bump a package to its latest release AND refresh the hash in one step:
  ```
  nix run nixpkgs#nix-update -- --flake --version=stable pkg-readsb
  ```
  (`--version=branch` to follow a branch head instead of a tag.)
- Just compute a hash for a known source:
  ```
  nix run nixpkgs#nix-prefetch-github -- wiedehopf readsb --rev v3.14.1623
  nix run nixpkgs#nurl -- https://github.com/wiedehopf/readsb v3.14.1623
  ```

### Changing a package's version or revision

Edit `rev` / `version` in the derivation, set `hash = lib.fakeHash;` (or leave
the old hash), then run `bash pkgs/update.sh <name>`. The derivations here pin
`rev` to a branch (`master`) for now; pin a tag or commit before a release so
builds stay reproducible.

### Updating the pinned nixpkgs

The nixpkgs snapshot that every environment builds against lives in `flake.lock`.
To move it forward:

```
nix flake update              # update all inputs
nix flake update nixpkgs      # just nixpkgs
```

Then re-run the CI eval-check (or `nix eval .#devShells.x86_64-linux.<env>.drvPath`
locally) to catch any packages the new nixpkgs renamed or dropped.

### Vendor blobs (`vendor/`)

These use `requireFile`, so their hash is the hash of the file you downloaded:

```
nix hash file signal_hound_sdk.zip   # prints sha256-...
```

Paste it into the derivation's `hash =`.
