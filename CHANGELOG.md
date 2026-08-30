# Changelog - RF-Swift-nix

Reproducible Nix environments and packages for RF Swift. Format based on
Keep a Changelog (https://keepachangelog.com). Dates are ISO-8601.

## [Unreleased] - v1.0.0-dev

First development line of the RF Swift Nix engine flake, tracking the RF Swift
binary's v4.0.0-dev.

### Added

- `rfswift-udev-rules` now also covers HydraSDR (vendor 38af, plus the NXP DFU
  mode); its legacy 1d50:60a1 id is already covered by the Airspy rule. So any
  environment that pulls in the consolidated rules (all the device envs) makes a
  HydraSDR usable without root, even one added to a non-SDR environment.
- udev-rule coverage for hardware whose package shipped none, so `rfswift nix
  udev` can make the device work without root: HydraSDR (libhydrasdr now
  installs the repo's own 51-hydrasdr.rules on Linux - the CMake install had
  been disabled to keep the macOS build working), Saleae Logic (99-SaleaeLogic
  .rules), and NanoVNA (70-nanovna.rules on nanovna-saver). DSView now installs
  its official DreamSourceLab rule from source (see Changed).

### Changed

- `dsview` is now built from source from the PentHertz DSView fork (v1.3.4)
  instead of the prebuilt amd64 .deb, reusing the nixpkgs CMake/Qt5 recipe with
  the source swapped and the install paths fixed in postPatch. It therefore
  builds on aarch64 and macOS as well (`platforms = unix`), not only x86_64
  Linux, and its own build installs the DreamSourceLab udev rule (vendor 2a0e)
  into the output for `rfswift nix udev`.

### Added

- Network environment coverage: added the general_network image tools that were
  missing. From nixpkgs: `arping`, `inetutils` (telnet), `lighttpd`, and `kea`
  (the DHCP server, ISC's successor to the removed isc-dhcp-server). Built from
  source under pkgs/sec/ (not in nixpkgs): `hexhttp` (HExHTTP), `argus-recon`,
  `above`, `crypto-condor`, `wiretapper` (all Python); `voipire`, `vortix`,
  `netwatch-tui` (Rust); `snitch`, `whosthere`, `brutus`, `nerva`, `mic`,
  `betterleaks`, `titus` (Go - nerva/titus need Go 1.27); and the Bash/Perl
  orchestrators `nmapautomator`, `subenum`, `webcopilot`, `mbtget`. The three
  Bash orchestrators put the recon tools they drive on PATH, skipping any not in
  nixpkgs.
- `littlesnitch` (pkgs/littlesnitch.nix): Little Snitch for Linux (obdev.at, the
  per-application network monitor/firewall the images install in their core
  build). Packaged from obdev's self-contained musl tarball - the `littlesnitch`
  binary is a statically linked ELF, so it needs no autoPatchelf - for
  x86_64/aarch64/riscv64 Linux, and added to the network environment. Proprietary
  (unfree); the daemon needs CAP_BPF/CAP_SYS_ADMIN/CAP_DAC_READ_SEARCH/CAP_PERFMON
  and root at runtime. macOS Little Snitch is a different product (a GUI app with
  a Network System Extension, installed from obdev's .dmg) and is not packaged
  here - a system extension cannot be delivered through the Nix store.
- `jss7` (pkgs/sec/jss7.nix): the RestComm/Mobicents SS7 stack
  (MTP/M3UA/SCCP/TCAP/MAP/CAP/INAP), built from source with
  `maven.buildMavenPackage` (JDK 11) and added to the `telecom` and
  `telecom_5g_bladerf` environments. It is a library (no CLI); its module JARs
  install under `share/java`. Its `mvnHash` is a placeholder pending one real
  build - the Maven dependency closure is the single fetch the CI sandbox cannot
  complete on its disk quota; the derivation evaluates and is otherwise complete.
- `blerp` (pkgs/sec/blerp.nix): the BLERP BLE Re-Pairing Attacks PoC, in the
  `bluetooth` environment. The pinned nRF firmware images (bleshell/blehci) ship
  in the closure; because the Python MitM host needs a custom Scapy fork, the
  `blerp-mitm` launcher builds that venv with `uv` at first run (from
  python-host/requirements.txt) rather than pinning a fast-moving fork - so the
  first run fetches the fork and the cffi/cryptography wheels, everything else is
  pinned.
- `breaktooth` (pkgs/sec/breaktooth.nix): the Breaktooth PoC (BR/EDR
  power-saving session hijack and HID keystroke injection, breaktooth.dev),
  built from source in the `bluetooth` environment instead of being a gap. Its
  real dependencies (PyBluez, dbus-python, PyGObject, colorama, pyudev, evdev,
  BlueZ) are wrapped around the attacker scripts - upstream's `requirements.txt`
  is a full Raspberry Pi OS `pip freeze` and is ignored - and the pure-stdlib Go
  `chg_bt_addr` BD_ADDR helper is compiled offline. Exposes `breaktooth`,
  `breaktooth-kb-server`, `breaktooth-injector` and `breaktooth-chg-bt-addr`.
- `gr-htra` (pkgs/oot/gr-htra.nix) and `gr-signal-hound`
  (pkgs/oot/gr-signal-hound.nix): the dedicated GNU Radio OOT source blocks for
  Harogic and Signal Hound receivers, matching RF-Swift-images'
  `grhtra_grmod_install` / `grsignalhound_Receiver_grmod_install`. Both are
  bundled into `gnuradio-rfswift` (so the blocks appear in gnuradio-companion,
  not just next to it) and link the SDKs already packaged under `vendor/`
  (`harogic-htra-sdk`, `signalhound-sdk`) - `gr-htra` through the upstream
  `HTRAAPI_INCLUDE_DIR`/`HTRAAPI_LIBRARY` cache variables, `gr-signal-hound` by
  rewriting its hard-coded `/usr/local/lib/lib*_api.so` link paths to the Nix
  SDK. Each is platform-gated (gr-htra x86_64-linux only, gr-signal-hound
  Linux only) so the bundle still evaluates on macOS and aarch64. This closes
  the gap where Harogic and Signal Hound worked in SDR++ and URH but had no
  GNU Radio block.
- `beef` (pkgs/beef): BeEF, the Browser Exploitation Framework, now shipped in
  the `network` environment instead of being a documented gap. Its gem closure
  is built with `bundlerEnv` from the upstream
  Gemfile.lock, with a pinned bundix-generated `gemset.nix`; BeEF's own `beef`
  launcher is wrapped with that Ruby, and `nodejs` (execjs) plus `espeak`
  (espeak-ruby) are put on its PATH.
- `rfswift-gl` (pkgs/rfswift-gl.nix): the OpenGL/EGL runtime for hosts that
  are not NixOS, shipped in every Linux environment. nixpkgs' Mesa and
  libglvnd look for GPU drivers in `/run/opengl-driver` only, so SDR++, gqrx
  and every other GUI tool failed EGL/GLX initialisation elsewhere. The
  package writes `share/rfswift/gl.env` (the variables pointing the loaders at
  Mesa's drivers from this pin, read by the RF Swift engine) and a
  `rfswift-gl <program>` wrapper for manual use. `rfswift-gl-nvidia` builds
  the matching proprietary NVIDIA user-space libraries impurely
  (`RFSWIFT_NVIDIA_VERSION`, optional `RFSWIFT_NVIDIA_HASH`) and keeps Mesa
  behind them for hybrid GPUs; it also exports
  `__EGL_EXTERNAL_PLATFORM_CONFIG_DIRS` so Wayland/GBM windows work on NVIDIA.
  Both variants ship `rfswift-gl-probe`, a windowless EGL client that creates
  a context the way GLFW/Qt tools do and prints the driver that answered (what
  `rfswift nix gl --check` runs). Intel, AMD, VMware/virtio and every other
  open driver are served by Mesa from this pin; macOS needs nothing.
- `kc908-sdk` (pkgs/vendor): the Deepace KC908 host libraries from the
  PentHertz mirror (FTDI D3XX, libkcsdr + kcsdr.h, the FTDI udev rule), x86_64
  Linux only, listed in `sdr_light` and `sdr_full` so `rfswift nix udev`
  installs its rule.

### Changed

- `sdrpp-hydrasdr` now builds the vendor device sources RF Swift's images
  ship, from source against this SDR++ core instead of prebuilt plugins, each
  only on the architectures its library exists for: Harogic (x86_64/aarch64
  Linux, `harogic-htra-sdk`), SignalHound BB60 (x86_64/aarch64 Linux and
  aarch64-darwin, `signalhound-sdk`; the module is grafted from the PentHertz
  fork, which carries it), Deepace KC908 (x86_64 Linux, `kc908-sdk`; the
  driver's Windows-only `Sleep` and OVERLAPPED arguments are patched for the
  Linux D3XX API). Its SoapySDR source now links RF Swift's
  `soapysdr-with-plugins`, which is how RFNM reaches it (the fork's native
  rfnm_source targets a librfnm snapshot no released API matches, so it stays
  off). `passthru.vendorSources` lists what a build carries. `kc908` keeps only
  the KCSDI AppImage.
- gqrx, SigDigger (with suscan), rtl_433 and SatDump are rebuilt on RF Swift's
  `soapysdr-with-plugins` (HydraSDR, RFNM, XTRX, LiteX M2SDR and uSDR next to
  the nixpkgs modules) instead of nixpkgs' set; gqrx gets the PentHertz
  gr-osmosdr (native HydraSDR) on the full GNU Radio it is built against, and
  SatDump additionally builds its LimeSDR, USRP and SoapySDR source plugins
  (checked at install time). gr-osmosdr-penthertz itself links that plugin
  set, so GNU Radio flowgraphs see the same devices.
- `luaradio-hydrasdr` puts the device libraries its LuaJIT backends dlopen by
  name (rtl-sdr, HackRF, Airspy, Airspy HF+, HydraSDR, bladeRF, UHD, SoapySDR)
  on its library path; they were silently "not available" before.
- Vendor packages use the top-level `libx11`/`libxcb`/`libxext`/`libxrender`
  attributes (the `xorg.*` set is deprecated and warned on every evaluation).

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

- `angr` (reversing) now imports and is shipped in the environment instead of
  being a documented gap. This nixpkgs pin ships pycparser 3.00, which removed
  the PLY C parser angr's C-type engine drives; pkgs/angr.nix builds angr
  against a python whose pycparser is pinned back to 2.22, scoped via
  `packageOverrides` so only angr's own closure (cffi and dependents) rebuilds
  and the global python/meson stack keeps its binary-cache hits. angr's runtime
  PYTHONPATH carries pycparser 2.22 only.
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

- `gr-DCF77_Receiver` (sdr_full): ships only GRC flowgraphs/scripts, no CMake
  module to install.
