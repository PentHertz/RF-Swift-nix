# Changelog - RF-Swift-nix

Reproducible Nix environments and packages for RF Swift. Format based on
Keep a Changelog (https://keepachangelog.com). Dates are ISO-8601.

## [Unreleased] - v1.0.0-dev

First development line of the RF Swift Nix engine flake, tracking the RF Swift
binary's v4.0.0-dev.

### Added

- Added Tailcat to the network environment, pinned from Tailscale's upstream
  repository. It provides netcat-style encrypted peer-to-peer transport over
  the Tailscale WireGuard/DERP data plane without its control plane.
- Added an opt-in `pkg-gnuradio4`, pinned to 4.0.0-RC2 from the new official
  `gnuradio/gnuradio4` repository. Its FetchContent dependencies are pinned for
  sandboxed builds, its optional memory-prohibitive generated registry is
  disabled, and GNU Radio 3.10 remains the default in SDR profiles.
- Updated the pinned Signal Hound SDK to 08_26_26, Spike to 4.0.16, and VSG60
  to 2.0.3 to match the current RF Swift images.
- Matched the shared SDR image device base more closely in both `sdr_light`
  and `sdr_full`: PlutoSDR, SoapyRemote, SoapyUHD and SoapyBladeRF are explicit,
  and the pinned Signal Hound Spike/VSG60 and Harogic SAStudio frontends are
  included on x86_64. The Signal Hound SDK covers BB60/BB60D, SM200, SP145, SA
  and VSG60 families.
- Added the available VNA/calibration applications from the light image to both
  SDR profiles: NanoVNA Saver, NanoVNA-QT, LibreVNA and xnec2c. Remaining
  calibration helpers are recorded in the catalog gap list until packaged.
- Device-bearing environments now declare explicit prerequisite layers. RF
  Swift realises these driver/library closures before applications in eager and
  pure modes, and automatically before the first requested tool in lazy mode.
- Added `gnuradio-rfswift-light`, matching the Docker `sdr_light` GNU Radio
  layer (GNU Radio + PentHertz `gr-osmosdr`) without pulling in `sdr_full`'s
  extended OOT collection.
- Added the pinned LibreSDR B210/B220 FPGA firmware and a Nix-safe
  `libresdr_swapfpga` utility. It uses a writable per-user UHD image directory,
  supports select/status/restore and can launch a UHD application with the
  chosen image without modifying the immutable Nix store.
- Pinned Proxmark3 RRG/Iceman client revision `b4c4edd7c`, matching the RF
  Swift RFID container and its current firmware capabilities protocol. This
  replaces nixpkgs 4.21128, which rejected newer PM3 firmware after opening it.
- The reversing environment's standard `ghidra` command now resolves to RF
  Swift's hash-pinned Ghidra 12.1.3 package instead of nixpkgs 12.1.2, matching
  the latest official NSA release while remaining reproducible.
- SDR++ builds its upstream and RF Swift HydraSDR modules from source across
  supported architectures, with install-time checks for the HydraSDR and Soapy
  source plugins. The external KC908 plugin remains x86-64-only and separate
  until its matching `libkcsdr` and VOLK runtime can be packaged reproducibly.

- 14 environments (`ad`, `android`, `automotive`, `bluetooth`, `cyberether`,
  `hardware`, `network`, `osint`, `reversing`, `rfid`, `sdr_full`, `sdr_light`,
  `telecom`, `wifi`) generated from `environments.nix` into `catalog.json`.
- GNU Radio OOT modules: the full default set from RF-Swift-images
  (`scripts/gr_oot_modules.sh`) - 53 modules build and are bundled into
  `gnuradio-rfswift`, including gr-lora, gr-inspector, gr-gfdm, gr-dvbs2, the
  Sandia suite (pdu/timing/sandia/fhss_utils), gr-m17, gr-nrsc5, gr-aaronia_rtsa,
  gr-dsd, gr-mixalot, gr-flarm, gr-droneid, gr-radar, gr-ieee80211 and more.
  Supporting out-of-nixpkgs deps packaged: itpp, turbofec, CRCpp, an HDC-patched
  fdk-aac, and libspectranstream.
- Many source-built / forked tools not in nixpkgs (MobSF, OpenBTS 2G/3G,
  CyberEther, OpenBTS-UMTS + asn1c 0.9.23, sslyze, and others).
- `scripts/security-audit.sh` + the flake `audit` app: layered vulnerability /
  supply-chain / integrity / configuration audit (vulnix, syft, grype,
  osv-scanner, `nix store verify`, signature provenance, flake.lock and
  placeholder-hash and insecure-package checks). Fault-tolerant, colour + emoji
  report, `--format stdout,txt,json,html,pdf`, `--fail-on`, and `--image` for
  container images.
- `scripts/update-sources.sh`: check for, and re-pin (rev + hash), the git
  sources of packages; `--refresh-hashes` repairs stale hashes.
- CI: `.github/workflows/ci.yml` handles evaluation and catalog synchronization;
  independent amd64, native arm64, and QEMU-backed riscv64 workflows build and
  cache each environment without cross-architecture cancellation. Each cache
  workflow uploads raw logs plus JSON and Markdown failure reports.
  `.github/workflows/security-audit.yml` provides the weekly, manual, and PR
  security audit.
- `tests/verify.sh` (evaluation ground truth) and
  `tests/smoke-environment.sh <env>` (closure build + declared-command check).
- Docs: `docs/verification-audit.md`, `docs/remaining-work.md`,
  `docs/ci-cd.md`, `docs/updating.md`.

### Fixed

- Pinned SSTImap to an immutable upstream commit and refreshed its source hash,
  fixing the `network` cache job after upstream `master` moved.
- Corrected the Nix SDR image mapping: `sdr_light` and telecom now use the light
  GNU Radio/OOT set, while `sdr_full` alone bundles the extended OOT batches.
  Remaining image-only device modules are listed explicitly in `missing`.
- The PentHertz `gr-osmosdr` build now receives `libhydrasdr`, enabling its
  HydraSDR source instead of silently disabling it during CMake configuration.
- `reversing` now uses the supported, binary-cached
  `wineWow64Packages.stable` for x64dbg and OllyDbg. This removes the deprecated
  `wineWowPackages` warning and avoids compiling Wine locally, substantially
  reducing temporary disk usage during environment creation.
- Added DSView to the `reversing` environment and regenerated both the flake
  catalog and the catalog embedded in the RF Swift binary.
- Cross-cutting build fixes for the current nixpkgs pin: gcc-15 build breakage
  (std::complex, deprecation-as-error), Python 3.14 packaging (mitmproxy wheels
  for MobSF, `pkg_resources` removal handled for unblob's `fs`, billiard's
  sandbox-racy test), drozer's `d8` dexer shebang, Wifiphisher/roguehostapd
  cleanup guards, and `tests/verify.sh` quoting of dotted package attributes.

### Known gaps (documented)

- `angr` (reversing): incompatible with this nixpkgs' pycparser 3.00; kept
  packaged, listed as a gap until nixpkgs' angr supports it.
- `gr-DCF77_Receiver` (sdr_full): ships only GRC flowgraphs/scripts, no CMake
  module to install.
- BreakTooth (bluetooth), jSS7 (telecom), BeEF (wifi): documented upstream gaps.
