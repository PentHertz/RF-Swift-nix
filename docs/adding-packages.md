# Adding and updating RF Swift Nix packages

The short version: use `scripts/package-maintenance.sh`. It keeps package
creation, hashes, builds, the catalog, and commercial downloads consistent.

## Select the RF-Swift-nix repository release

The unqualified GitHub flake follows the repository's default branch:

```console
nix build github:PentHertz/RF-Swift-nix#network
rfswift run --engine nix --flake github:PentHertz/RF-Swift-nix -i network -n latest
```

Once a repository tag has been published, append it to select that complete,
reproducible RF Swift Nix release instead:

```console
nix build github:PentHertz/RF-Swift-nix/<tag>#network
rfswift run --engine nix --flake github:PentHertz/RF-Swift-nix/<tag> \
  -i network -n pinned
```

An exact commit can also be selected with
`github:PentHertz/RF-Swift-nix?rev=<40-character-commit>`. Set
`RFSWIFT_NIX_FLAKE` to any of these references to make it the default for new
missions. Existing mission manifests retain the flake reference used when they
were created, so a tagged mission does not silently jump to `main`.

Repository tags choose the complete package/catalog snapshot. Versioned package
attributes, such as the Harogic compatibility packages below, choose a specific
tool version inside that snapshot. Publishing a `v*` tag also starts this
repository's architecture cache workflows.

## Add a straightforward package

Choose `go`, `rust`, `python`, or `cmake`:

```console
scripts/package-maintenance.sh new mytool go owner/repository --branch main
```

For a prebuilt commercial or upstream binary:

```console
scripts/package-maintenance.sh new mytool binary https://vendor.example/mytool.tar.gz
```

Review its archive layout, install phase, license, and supported platforms
before prefetching it. A template cannot infer those safely.

This creates `pkgs/mytool.nix` and registers `pkg-mytool`. Open the file and
replace its `TODO` description, license, sub-package/module settings, and any
dependencies. Add `"mytool"` to the appropriate package list in
`environments.nix`, then run:

```console
scripts/package-maintenance.sh prefetch mytool
scripts/package-maintenance.sh check mytool
scripts/package-maintenance.sh catalog
```

Commit the package, `pkgs/default.nix`, `environments.nix`, and regenerated
`catalog.json`. If the sibling RF-Swift checkout is present, synchronize its
embedded copy explicitly:

```console
cp catalog.json ../RF-Swift/go/rfswift/nix/catalog.json
```

`--branch main` records `updateBranch = "main"` but resolves and pins the current
commit as `rev`, so builds stay reproducible. Use `--rev <commit>` for a package
that must not follow a branch. Release-based packages can change `rev` to a tag
and use `update --version ...`.

Bulk source updates only move packages that explicitly declare `updateBranch`.
Packages created with `--rev`, release tags, and other fixed pins are reported
as fixed and are never moved to GitHub's default branch implicitly. A one-off
maintainer override remains available with `scripts/update-sources.sh --branch
BRANCH --only NAME --write`.

The declarative builder is intentionally limited. Keep a normal derivation for
packages needing patches, several sources, old Python versions, special wrappers,
or platform-specific logic. The same `check`, `update`, and `prefetch` commands
still work for those packages.

## Update an open-source package

Ask `nix-update` to select the newest stable release and update source/build
hashes:

```console
scripts/package-maintenance.sh update mytool
scripts/package-maintenance.sh check mytool
```

For a known version:

```console
scripts/package-maintenance.sh update mytool --version 1.4.2
```

For a branch/commit package, edit `rev` and `version`, then run `prefetch`.
Always review `git diff`; version updates can require source patches or new
dependencies even when hashes were updated successfully.

## Update a commercial SDK or application

Commercial download metadata has one home: `pkgs/vendor/sources.json`.
The following downloads the new artifact, computes its Nix hash, and updates
the version, URL, and hash atomically:

```console
scripts/package-maintenance.sh vendor-update signalhound-sdk 08_26_26 \
  https://signalhound.com/sigdownloads/SDK/signal_hound_sdk_08_26_26.zip
scripts/package-maintenance.sh check signalhound-sdk
```

For a vendor application with a different archive per CPU, update every
declared artifact explicitly:

```console
scripts/package-maintenance.sh vendor-update sastudio 4.4.55.48 \
  https://example.invalid/SAStudio_amd64.zip --system x86_64-linux
scripts/package-maintenance.sh vendor-update sastudio 4.4.55.48 \
  https://example.invalid/SAStudio_arm64.zip --system aarch64-linux
```

The audit requires `artifacts` and `platformPaths` to contain the same systems,
which prevents a release from silently updating only one architecture.

### Harogic compatibility versions

Harogic SDK releases are intentionally kept side by side because a newer SDK
can be unstable with some deployed devices. The environment uses the documented
default, while a customer can install a known-good version explicitly:

```console
rfswift nix install harogic-htra-sdk-0_55_64
rfswift nix install harogic-htra-sdk-0_55_88
rfswift nix install sastudio-4_3_55_35
rfswift nix install sastudio-4_4_55_48
```

When adding a Harogic SDK or SAStudio release, add a new entry and versioned
package alias; do not delete the previous supported entry. Change the
unversioned `harogic-htra-sdk` or `sastudio` alias only after the new release
has been validated. This makes rollback a package selection instead of a
source-code revert. Keep SDK and SAStudio versions from the same vendor release
tag together when customer compatibility requires the matched pair.

If an SDK changes its archive layout, also update `platformPaths` and the
extraction logic in `pkgs/vendor/default.nix`. Never reuse Linux AArch64 ELF
libraries on macOS; Apple Silicon must use the SDK's Mach-O `macos_arm` files.

Review all pins and optionally verify their URLs:

```console
scripts/package-maintenance.sh vendor-report
scripts/package-maintenance.sh vendor-report --check-urls
```

## Validate a contribution

Fast checks:

```console
scripts/package-maintenance.sh audit
scripts/package-maintenance.sh check mytool
./tests/verify.sh
```

`check` evaluates metadata, builds the package, and confirms `meta.mainProgram`
exists when declared. `audit` rejects fake hashes, validates vendor metadata,
checks shell syntax, and evaluates catalog generation. CI additionally checks
catalog synchronization and every environment on supported architectures.

## Common failures

- **Hash mismatch:** run `prefetch NAME`; do not paste the `specified:` hash.
- **Go vendor hash mismatch:** `prefetch` repeats so it can pin the source and
  module closure separately.
- **Package builds but is absent:** add its exact attribute name to
  `environments.nix`, regenerate the catalog, and check `meta.platforms`.
- **Commercial URL returns 404:** update `sources.json` through `vendor-update`;
  do not add mirrors whose redistribution terms are unclear.
- **Wrong CPU architecture:** inspect the output with `file`/`readelf`. Vendor
  packages must select an explicit platform path, never the first library found.
