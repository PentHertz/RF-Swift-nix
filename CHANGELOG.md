# Changelog - RF-Swift-nix

Reproducible Nix environments and packages for RF Swift. Format based on
Keep a Changelog (https://keepachangelog.com). Dates are ISO-8601.

## [Unreleased] - v1.0.0-dev

First development line of the RF Swift Nix engine flake, tracking the RF Swift
binary's v4.0.0-dev.

### Build fixes for the 2026-10-23 pin (2026-10-24)

The 75ba8332 pin broke bluetooth, hardware, network, reversing, sdr_full,
sdr_hacks, sdr_light and the four telecom environments in the cache builds.

Fixed:

- pyqt6 on macOS (GNU Radio, pyqtgraph, URH, gqrx, nanovna-saver, ...):
  `QtCore.abi3.so` failed to load (`symbol not found in flat namespace
  __ZN13QPyTableRange16staticMetaObjectE`). qtbase 6.12's Darwin
  `include/QtCore/*.h` are `#include_next` forwarders into QtCore.framework,
  which moc cannot follow when `<qtbase>/include` precedes `-F<qtbase>/lib`,
  so QT_VERSION was undefined while moc ran and it skipped
  qpycore_qrangemodel.h, the one moc'd header gated on it. That guard now
  also holds under `Q_MOC_RUN` (Darwin only; Linux pyqt6 stays cached).
- angr (reversing): nixpkgs' suite is consistent again at 10.0.4 (claripy
  and ailment merged into angr) and works with pycparser 3.00, so
  pkgs/angr.nix and its 9.2.154 downgrade are gone. The downgrade had
  started building 9.2.154 with 10.0.4's Rust `cargoDeps` (no Cargo.lock).
- Cutter: Qt 6.12's uic rejects `AddressableItemList<>` as a .ui class
  name. Patched as in upstream's open rizinorg/cutter#3670 (an
  `AddressableItemListView` alias).
- semgrep 1.180 imports `mcp.server.fastmcp`, gone in the pin's mcp 2.x:
  built against nixpkgs' `mcp_1`. On Linux its prebuilt semgrep-core also
  made patchelf abort (`shiftFile: splitIndex == -1`) when growing .interp
  and the rpath at once; the rpath is now `$ORIGIN/libs:<glibc>/lib`, which
  fits in place.
- amaranth 0.5.10 and glasgow (hardware) pin `pyvcd<0.5`; the pin has
  0.5.0, whose breaking changes neither uses (amaranth-lang/amaranth#1686).
  The pin is relaxed.
- threat9-test-bed (routersploit's test dependency, network): setuptools-scm
  10.2 rejects its absolute `write_to`; made relative.
- jSS7 (telecom, telecom_5g_*, telecom_ltesniffer): Maven 3.10 refuses the
  WildFly extension's duplicate `wildfly-controller` declaration (3.9 only
  warned). The duplicate is dropped and `mvnHash` regenerated (identical
  on x86_64-linux and aarch64-darwin).

### Security fixes and version refresh (2026-10-23)

Security:

- nixpkgs moved to 75ba8332 (master as built by Hydra on 2026-10-23;
  nixos-unstable, 2026-10-20, predates the fixes below):
  - PHP2Shell (CVE-2026-109618, CVE-2026-109619): PHP 8.5.12, 8.4.27 and
    8.3.36. In the environments PHP serves fluxion's captive portal.
  - eMudhra CA compromise: `cacert` 3.131.1, whose NSS 3.131.1 root set drops
    emSign ECC Root CA - G3, emSign Root CA - C1 and emSign ECC Root CA - C3,
    the roots of the leaked intermediates (curl, OpenSSL, Python's certifi
    and the JDK's cacerts use it); Go 1.26.10 / 1.27.3 (CVE-2026-111943,
    which rejects chains through those intermediates) for every Go tool,
    tailcat included (it builds with nixpkgs' Go 1.27 again instead of its
    private 1.27.1); Firefox 158.0.1; Electron 42.11.18 / 43.8.3 / 44.9.3;
    uv 0.13.5 (packaged here, nixpkgs has 0.13.4: 0.13.4 drops the roots
    from uv's own store, 0.13.5 moves `uv python install` to CPython builds
    whose pip 26.2.2 and certifi 2026.10.19 drop them too).
  - Node2Shell (CVE-2026-111497, Brotli decoder): Node.js 22.23.4 and
    26.12.1 with nixpkgs' patched brotli. BeEF, the one tool here that runs
    Node at runtime, uses Node 26 until the pin's default Node 24 is fixed.
- Still open on this pin, pending nixpkgs' staging branch: Node.js 24.22.1
  (the default `nodejs`, used here only at build time) and brotli 1.2.1 for
  the system library curl, Wireshark and Python's brotli link. Rebuilding
  either here would rebuild most of the closure (Qt WebEngine, WebKitGTK,
  GTK4, ...) from source; the next `nix flake update` after they reach
  nixpkgs master picks both up.

Changed (latest upstream releases or branch heads):

- Releases: AIS-catcher 0.70, dumphfdl 1.7.0, dumpvdl2 2.7.0, libacars
  2.2.1, readsb 3.16.17, osmo-fl2k 0.2.1, CyberEther 1.16.2 (source build,
  plus its new pocketfft subproject, and the release binaries), Ghidra 12.2,
  Joern 4.0.665, pwndbg 2026.10.22, x64dbg 2026.05.27, MobSF 4.5.3 (with
  mitmproxy-rs/mitmproxy-linux 0.12.15, yara-python-dex 1.1.0 and APKiD
  3.2.0; lief stays 0.17.6, the newest MobSF accepts), HExHTTP 2.7, the
  ChameleonUltra CLI's bundled xz 5.8.4.
- Branch heads: Proxmark3 / Proxmark5 (v4.23346-211), SDR++, NFC
  Laboratory, gqrx-scanner, pySim, OCUDU, usdr-lib, OP25, libhydrasdr
  (1.1.3+), CRCpp, Mtk79ICAP, gr-dab, gr-m17, gr-radio_astro, SCAT (now
  2.1.2; its build uses hatch-vcs), wifit3, WireTapper, SIPPTS, brutus,
  Nerva, titus, whosthere, betterleaks, mic, blackbird, sparrow-wifi,
  reFlutter, fluxion (6.32+) and BeEF's tree. brutus and whosthere now need
  Go 1.27.
- `airgorah` 0.9.0 (nixpkgs has 0.8.1), following RF-Swift-images after
  v1.2.0: the GUI now drives a privileged `airgorah-agent` that must sit next
  to it, so both are installed side by side, with ip, crunch and xterm added
  to its PATH.
- Following RF-Swift-images' `ubuntu_resolute` commits of 2026-10-23: every
  environment's `go` is now Go 1.27.3 (nixpkgs' default is still 1.26) and
  its `uv` 0.13.5, and the android environment's `ipsw` is 3.1.739 (nixpkgs
  has 3.1.736; it now needs Go 1.27). uv and ipsw are overrides of the
  nixpkgs packages that step aside once nixpkgs reaches those versions; until
  then uv builds from source. The other bumps there, Ghidra 12.2 and
  CyberEther 1.16.2, were already in.
- Already current and unchanged: Signal Hound SDK 10_05_26, Spike 4_0_17 and
  VSG60 2_0_5, Burp Suite 2026.9.2, Saleae Logic 2.4.48, Little Snitch
  1.1.0, KC908 0.5.11-72, Harogic 0.55.88, sslyze 6.3.1, and the other ~150
  commit-pinned packages, already at their upstream heads.
- Kept on purpose: mmt-dpi (newer commits drop `update_http2_data`, which
  5Greplay still calls), pyrit, crypto1_bs, certsync's Certipy
  4.8.2, OAI's asn1c and SIMDE commits, GNU Radio 4's dependency set.

Fixed:

- gr-ais, gr-gsm, gr-limesdr, gr-rds and gr-satellites named a branch
  (`maint-3.10`, ...) as their `rev` with a fixed hash, which breaks as soon
  as the branch moves (gr-rds' already had): pinned to commits. The SCAT
  Wireshark dissector and crypto1_bs' miLazyCracker patch were fetched from
  `master` URLs the same way and are now pinned too.
- The flake's `rich` test-skip override now applies only where rich builds
  from source anyway (non-default Python sets, riscv64). nixpkgs made rich a
  build input of scons, so overriding the default one rebuilt scons, ffado,
  PipeWire, GTK4, GStreamer, Qt and their dependents from source.
- `overlays.default` hit infinite recursion on dsview, ad-miner, wifite2 and
  certsync (and on the new airgorah, uv and ipsw): each overrides the nixpkgs
  package of the same name, which callPackage resolved to the overlay's own
  attribute. They now take it from the base package set. The environments
  were not affected (they do not go through the overlay).
- usdr-lib's `usdr.pc` joined `${prefix}` with absolute install dirs (and
  put libdir under bin/); it now uses the full dirs.
- pwndbg's .deb is now a relocatable bundle with its own ld.so, and its
  `usr/bin/pwndbg` an absolute symlink, so the old recipe produced no
  `bin/pwndbg`. It is installed as is (no ELF patching onto the Nix glibc),
  with `bin/pwndbg` pointing into the store copy.

### Synced with RF-Swift-images v1.2.0

Everything RF-Swift-images added between v1.1.3 and v1.2.0.

Added:

- `sdr_hacks` environment, for the images' new sdr_hacks add-on image:
  everything in sdr_light plus hardware that was never meant to be an SDR.
  Its two SoapySDR modules (`driver=mt7921`, `driver=espsdr`) are not folded
  into `soapysdr-with-plugins`, which would rebuild everything linked to
  SoapySDR: RF Swift already puts each environment profile's
  `lib/SoapySDR/modules*` on `SOAPY_SDR_PLUGIN_PATH`, so every tool of the
  environment finds them.
  - `birriasdr`: an MT7921AU/MT7961 USB Wi-Fi dongle as a 40 MSps I/Q
    receiver over libusb (`birria_rx`, libbirriasdr), udev rule included;
    Linux and macOS.
  - `mtk79icap`: the same sticks as a SoapySDR source through a fork of the
    mt7921u driver - the SoapyMT7921 module, `mt7921iq_rx`, the firmware
    patcher `mt7961-iq-fw-v65` (works from the user's own linux-firmware copy)
    and `mt7921iq-setup`; the kernel driver is built on the host from
    `share/mtk79icap/driver`.
  - `w1700k-sdr`: the Gemtek W1700K router's MT7996 as an SDR - host tools
    (`w1700k-stream`, `w1700k-spectrum`, `sdr-recv`, built without
    `-march=native`), the MT7996 firmware set built here for bare-metal RV32
    with unwrapped clang/lld, and the `w1700k` CLI (over ssh).
  - `esp-sdr` (host tools, ESP-IDF sources and `espsdr-fetch-firmware`),
    `esp-sdr-bridge` (SpyServer/rtl_tcp server, with its v0.1.0 ESP32-S3
    firmware) and `soapyespsdr` (Linux; its Ethernet transport uses
    `SO_BINDTODEVICE`). The ESP-SDR prebuilt firmware set is republished under
    the same URLs with each release, so it cannot be pinned in the store:
    `espsdr-fetch-firmware` mirrors it on demand (the images' own script,
    every part sha256-checked against the manifest) and writes an esptool
    `flash.sh` per board.
  - `lr2021-sdr`: the Semtech LR2021 on an ESP32-P4 board - host libraries
    and tools, the Python TX/decode helpers and the v0.3.0 ESP32-P4 firmware.
    The fetch keeps only the two research files the tests read, not the
    repository's ~88 MB of captures.
  - esptool, picocom, tio and pyserial for flashing and consoles.
- `decsat` (sdr_full): DecSAT 0.10.17, a DVB-S2/S2X, DVB-S and SCPC
  satellite receiver, GUI and CLI, built from source with its libopus and
  libxaac submodules; the GUI's dlopened X11/Wayland/EGL libraries are on its
  RUNPATH, ffmpeg and curl on its PATH. Linux only, like upstream: on macOS
  libxaac's generic kernels are compiled out by Apple clang's `__ARM_NEON__`.
- `ad-miner` (ad): AD Miner 1.9.0 (nixpkgs has 1.8.1), with the images' fix
  for Python 3.14: its pool workers read a global only the parent process
  sets, which the new default `forkserver` start method leaves empty, so
  `fork` is forced.
- MediaTek Wi-Fi firmware reverse engineering (hardware): `mtkwifitools`
  (the single-file firmware tools, plus `mtk_ramreader` on x86_64, which links
  the repository's prebuilt x86-64 binutils archives), `mtkicaptool` (the
  ICAP spectrum plotter `mtk_icap_plot`, with adb), `mtkcsidump` (the PyQt5
  CSI client `mtk_csi_client`) and `mtkmon` (Nexmon for NDS32, sources).

Not carried over (listed in the environments' `missing`):

- MtkWifiTools' barepatcher: it edits and compiles code in its own checkout
  with a separately downloaded x86-64 NDS32 toolchain.
- Mtk79ICAP's kernel driver and patched firmware, and the W1700K router OS,
  which belong on the host or the device.

### Synced with RF-Swift-images v1.1.3

Everything RF-Swift-images added or bumped between v1.1.2 and v1.1.3.

Changed:

- `cyberether` 1.9.1 -> 1.15.0 (the images' v1.15.0). Upstream replaced its
  bundled SoapySDR stack with built-in drivers (the SDR and SDR Sweep blocks)
  for RTL-SDR, Airspy, Airspy HF+, HackRF, LimeSDR, bladeRF and PlutoSDR, which
  it links from ~10 new vendored subprojects. As the Soapy stack was, they are
  routed to nixpkgs, which carries the very releases the wraps pin (bladeRF
  2025.10, hackrf 2026.01.3, LimeSuite 23.11.0, libiio 0.26, libad9361 0.3;
  airspyhf is newer, 1.8.1), so no LimeSuite, bladeRF/no-OS, libiio or libxml2
  is compiled. The remaining SoapySDR block now dlopens libSoapySDR at
  runtime: the wrapper points `CYBERETHER_SOAPYSDR_LIBRARY` at RF Swift's
  `soapysdr-with-plugins`, and its ABI check also accepts nixpkgs' snapshot
  ("0.8-3"; the bumps since "0.8" only added C++ API). The wrap list follows
  1.15.0 (cpp-httplib 0.56.0, toml++ 3.4.0, four more tree-sitter grammars)
  and the geodata grows to 26 files, 8 of them fetched from natural-earth-
  vector v5.1.2 as upstream's parser does. As in the images, only CyberEther
  and fmt are installed: the statically linked subprojects' headers, archives
  and .pc files (zlib, qrencode, tree-sitter, cpp-httplib) no longer land in
  the environment.
- `wifite2` moves to kimocoder's master (2.9.9-beta, 2026-10-10), which the
  images now install instead of derv82's frozen original. nixpkgs' recipe
  (2.7.0) is kept and its source moved forward: poetry-core build, requests
  and rich added, and hostapd, dnsmasq, wpa_supplicant, ip and iptables for
  the evil-twin attack on the wrapper's PATH. The bundled wordlist is
  installed and added to wifite's default search list (the images copy it to
  /usr/local/share/dict/wordlists), and so is the OUI table. John cracking
  chose `wpapsk-opencl` whenever john lists it, which nixpkgs' OpenCL-enabled
  john always does, and then cracked nothing without an OpenCL device (most
  non-NixOS hosts); it now takes that format only when `john
  --list=opencl-devices` shows a device. Three upstream tests are disabled: the
  aircrack-ng handshake check Debian also disables, a john banner regex, and a
  john round trip whose key is shorter than WPA's 8-character minimum.
- Signal Hound SDK 09_14_26 -> 10_05_26 (PCR API 1.0.10). On x86_64 the SDK is
  now unpacked from its Ubuntu builds only: every distribution's copy carries
  the same file name, so the one installed had depended on find's traversal
  order. TG ships Ubuntu 14.04 (1.1.0) and 24.04 (1.1.3) builds; the 24.04 one
  is installed, as in the images.
- `burpsuite` 2026.9.1 -> 2026.9.2 and `saleae-logic2` 2.4.46 -> 2.4.48.

Added:

- `wifit3` (wifi): derv82's standalone USB Wi-Fi auditor TUI, which drives
  Atheros, MediaTek, Realtek and Ralink dongles through its own user-space
  drivers (PyUSB, firmware bundled). Pinned to master, as the images install
  it; built with its test suite and upstream's `--smoke` self-test. nixpkgs
  builds libusb-package from source, so unlike the images (x86_64/aarch64
  wheels only) it also covers riscv64 and macOS.
- `cyberether-release` and the `cyberether_release` environment: CyberEther
  1.15.0 from upstream's prebuilt release tarballs, for x86_64 and aarch64
  Linux and aarch64 macOS. Nothing compiles, where the source build is a
  long serial C++ build. On Linux autoPatchelf ties it to nixpkgs' glibc, Vulkan loader, udev
  and libgudev, and what libjetstream dlopens (GLFW's X11/Wayland backends,
  miniaudio's ALSA/PulseAudio/JACK, libsecret) is on its RUNPATH. Its SoapySDR
  block accepts only SoapySDR 0.8.1's ABI, so that block finds no library here;
  the built-in SDR drivers are unaffected.

Not carried over:

- uv 0.13.1: the nixpkgs pin has 0.12.22 and nixos-unstable 0.13.0; it comes
  with the next nixpkgs move.
- SavvyCAN's Qt6 patch: the images build master, nixpkgs ships the V220
  release (Qt5), which needs neither change.

### Synced with RF-Swift-images v1.1.2

Everything RF-Swift-images added or bumped between v1.1.1 and v1.1.2.

Changed:

- nixpkgs moved to nixos-unstable 2026-10-10 (`6510408d`), which brings the
  toolchains the images bumped: Go 1.27.2 (`go_1_27`, used by nerva and titus;
  the environments' default `go` is nixpkgs' 1.26.8) and uv 0.12.22 (images:
  0.12.24, not yet in nixpkgs). Every environment and `pkg-*` still evaluates
  on x86_64/aarch64/riscv64 Linux and aarch64-darwin; the bump drops no
  package and restores apksigner and luaradio-hydrasdr on riscv64.
- `cyberether` builds with nixpkgs' meson (1.12.1 on this pin, CyberEther needs
  >= 1.11) instead of overriding it to 1.11.0. The override swapped only the
  source, so it kept nixpkgs' patches, which nixpkgs had rebased onto 1.12 and
  which no longer applied; meson also comes from the binary cache again. An
  assertion fails evaluation with a clear message should a pin ever ship an
  older meson.
- `satdump` builds again on aarch64-linux. GCC 16.2 (new with the nixpkgs
  bump) segfaults there while printing a `-Wpsabi` note ("parameter passing
  for argument of type 'std::pair<double, double>' ... changed in GCC 10.1")
  inside nlohmann/json's templates, an internal compiler error that failed
  sdr_full. The note is informational, so it is now silenced with
  `-Wno-psabi`, for GCC on aarch64 only (other platforms keep the identical
  derivation). Reproduced and verified with the x86_64->aarch64 cross GCC.
- `python3Packages.meshtastic` skips its test suite on every platform, not only
  macOS. Its test inputs are all its optional extras, which on Linux pulled
  pandas-stubs -> tables -> blosc2 -> torch and the GDAL/geopandas/xarray stack
  into sdr_full's build (49 derivations, a from-source PyTorch among them,
  whenever the dev cache lacks them, as right after a nixpkgs bump). None of it
  reaches the environment; the import check still runs. It also brings the
  meshtastic CLI back to sdr_full on riscv64, where those test inputs did not
  evaluate.
- Signal Hound SDK 08_26_26 -> 09_14_26, Spike 4.0.16 -> 4.0.17 and VSG60
  2.0.3 -> 2.0.5. Signal Hound renamed the Spike/VSG archives to
  `(Ubuntu_x64)`, so their version probes and platform paths follow; the VSG
  probe now reads the software page, where the download links moved.
- `ghidra` (ghidra-latest) 12.1.3 -> 12.1.4.
- `burpsuite` 2026.9.1, the release the images install: a local copy of the
  nixpkgs recipe (which is at 2026.8 and pins its version in a `let`), now
  declared Linux-only since it is a buildFHSEnv.

Added:

- `common-packages.nix`: the baseline every environment ships, shared by
  flake.nix and gen-catalog.nix. Besides python3/uv/go it now carries the CLI
  utilities of the images' corebuild `common_utils_install` (delta, hexyl,
  xxd, colordiff, jq, yq, ripgrep, fd, bat, tmux, mc, btop, htop, ncdu, pv, 7zz,
  zstd, lsof, strace, ltrace, openssh, net-tools, traceroute, dnsutils, xclip,
  xsel, ...). meld and recoll are left to the host desktop, and iputils /
  util-linux are left out because a store copy would shadow the host's setuid
  or capability-carrying binaries (ping, mount, su).
- New tools, from nixpkgs: `coercer` (ad); `mitmproxy`, `libimobiledevice`,
  `ideviceinstaller`, `usbmuxd`, `libusbmuxd`, `ifuse`, `ipsw` (android, iOS
  side); `python3Packages.udsoncan` (automotive); `crackle` (bluetooth);
  `net-snmp`, `samba` (network: the snmpwalk/smbclient AutoRecon's plugins
  call); `tio`, `python3Packages.pyftdi`, `glasgow` (hardware); `pwntools`,
  `capa`, `flare-floss`, `detect-it-easy` (reversing); `mfoc-hardnested`,
  `global-platform-pro`, `qFlipper` (rfid); `python3Packages.rfcat`,
  `killerbee` (sdr_light, sdr_full); `qcsuper` (telecom, telecom_5g_bladerf).
- New tools, built here (not in nixpkgs), each matching its image installer:
  `targetedkerberoast` (ad); `reflutter` (android); `python3Packages.doipclient`
  and `icsim` (automotive; ICSim's artwork path is compiled in, so it runs from
  any directory); `sweyntooth` (bluetooth; `sweyntooth --list`, the patched
  scapy it bundles, and the dongle firmware via `sweyntooth --firmware`);
  `baudrate` (hardware, RF Swift's serial baud-rate finder); `phoneinfoga`
  (osint, upstream release binaries, as nixpkgs dropped it) and `blackbird`
  (osint; state under `$XDG_DATA_HOME/blackbird`, reports in `./results`);
  `bytecaster` (reversing, `ByteCaster`); `ufbt` (rfid); `hostapd-wpe`
  (hostapd 2.11 + aircrack-ng's WPE patch, with a config that works from the
  store), `wpa-sycophant` and `eap-buster` (wifi).
- `python3Packages.chipwhisperer` (hardware): NewAE's ChipWhisperer API, which
  nixpkgs marks broken because 5.x and PyPI's 6.0.0 pin NumPy 1.26. Built from
  upstream's NumPy 2 line (tag `sca101_release`, 6.0.0) with its bundled FPGA
  bitstreams and MCU firmware (named in a MANIFEST.in, since setuptools-scm
  cannot list them without .git, and checked at build time) and a uaccess udev
  rule for NewAE devices.
- Two environments for the images' new telecom images, each with the
  telecom_utils set:
  - `telecom_5g_oai`: OpenAirInterface 5G v2.4.0 (`openairinterface5g`:
    `nr-softmodem`, `nr-uesoftmodem`, `nr-cuup`, the USRP/rfsim plugins it
    dlopen()s, and the sample configs in `share/openairinterface5g/conf`) with
    the Open5GS core. Built with CMake/Ninja exactly as `build_oai --gNB --nrUE
    -w USRP` would, against the asn1c fork and SIMDE commit OAI pins.
  - `telecom_ltesniffer`: LTESniffer (`ltesniffer`), with its srsRAN 4G fork
    pinned instead of cloned at configure time, and UHD and bladeRF radios.
  Both are x86_64-linux and target x86-64-v3 (AVX2/FMA; OAI also needs
  PCLMUL) instead of upstream's `-march=native`, which would tie the binary to
  the CPU that built it.
- Documented gaps: BlueToolkit (bluetooth; a root-only system installer) and
  RFQuack (sdr_full; ESP32 firmware that PlatformIO builds by downloading
  toolchains).

### Added

- Platform availability manifests at `availability.<system>.<environment>` and
  in installed environments at `share/rfswift/availability.json`, distinguishing
  present packages, unsupported platforms, missing attributes and evaluation
  failures. Installable environment and prerequisite builds now print omissions,
  not only development shells.

- `MAINTAINING.md`: the maintainer checklist on one page - updating git-pinned
  packages (rev + hash), moving the nixpkgs baseline, regenerating the catalog,
  verifying and pushing, what users run to receive an update, how to read a red
  CI run, and the traps that have bitten us (empty catalog, ripgrep,
  experimental features).
- `scripts/package-maintenance.sh flake-update [INPUT]`: `nix flake update`
  with the experimental features passed on the command line, so the nixpkgs
  baseline can be moved on a stock Nix install (no nix.conf changes needed).
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

- CI: development-line branches matching `v*-dev` (`v1.1.0-dev`, ...) are
  first-class: pushes to them and pull requests into them run `ci.yml`, the
  four cache workflows (riscv64 and darwin included) and the security audit,
  exactly as for `main`. The pattern is a branch filter, so it never matches
  the `v*` release tags.
- CI: every GitHub Action is pinned by commit to its current release
  (`actions/checkout` v7.0.1, `upload-artifact` v7.0.1, `download-artifact`
  v8.0.1, `cachix/install-nix-action` v31.11.1, `peter-evans/create-pull-
  request` v8.1.1, `github/codeql-action` v4.37.9, `docker/setup-qemu-action`
  v4.3.0). The previous majors ran on Node.js 20, which GitHub is retiring
  (every job logged a deprecation warning and was forced onto Node 24).

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

- Installable environments failed to build on Linux after the availability
  manifest was added: it was copied from `buildEnv`'s `postBuild` into
  `share/rfswift`, a directory that only `rfswift-gl` provides in most
  environments, so `buildEnv` had linked it straight into that package's
  store path and the copy hit "Permission denied" (`sdr_full` and `sdr_light`
  passed only because `libresdr-firmware` provides the directory as well). The
  manifest is now a package of its own merged into the environment, which
  makes `share/rfswift` a real directory in every case.

- `build-cache-report.sh` understands the error format of Nix 2.30+ (the
  install-nix-action v31 bump): "error: Cannot build '<drv>'." followed by an
  indented reason and the builder's last log lines. The job summary now shows
  that block; before, a failed environment was reported without any cause.

- Tailcat's pinned 2026-09-05 revision requires Go 1.27.1, but the declarative
  builder selected Go 1.26.7. Select a source-hash-pinned Go 1.27.1 builder when
  the nixpkgs pin is older, and refresh the measured vendor hash. Serialize its
  E2E test cases to avoid a shared-fixture `text file busy` failure in the Nix
  sandbox, keeping the tests enabled. This addresses the `network` cache failure
  first reported against commit `443368e`.
- Tailcat's end-to-end tests no longer run inside the Nix sandbox. They
  compile a fixture, start a loopback DERP relay and expect a client and a
  server process to complete a WireGuard handshake within 10 s; on GitHub's
  runners that timed out in all three cache and CI runs of 2026-09-05
  (`TestServeWithoutPSK`, then the forward test) while the same derivation
  passed on a workstation. Upstream runs the suite in its own CI, so the
  package sets `doCheck = false`; the declarative Go builder now accepts
  `doCheck`. The dedicated "Tailcat toolchain, vendoring and tests" CI job is
  gone: the cache-amd64 network build already builds the same derivation on
  every push and pull request.
- `scripts/update-sources.sh` needed ripgrep (`rg: command not found` on a
  stock machine) to list the git-pinned packages; it now uses plain `grep`,
  like `package-maintenance.sh` already did when `rg` is absent. The only
  tools it still needs on the host are bash, grep, sed, awk and nix (git runs
  through `nix run nixpkgs#git`).
- `catalog.json` could be committed empty: the catalog app redirected `nix
  eval` straight into the file, so when the eval failed (see above) the file
  was truncated before the error showed, and `git add catalog.json` then
  committed 0 bytes (f4d99e4). In CI an empty catalog gave the cache workflows
  an empty build matrix: no build job ran and the `report` job died on
  `find: 'reports': No such file or directory`. Three fixes: the app now
  writes to a temporary file and renames it; the four cache workflows' prepare
  step fails with a clear error when the catalog yields no environment; and
  the report aggregation writes a "no report was uploaded" summary instead of
  failing when the download step left no directory behind, so the build jobs'
  own status tells the story.
- `nix run .#gen-catalog` (and `scripts/package-maintenance.sh catalog`) failed
  with `experimental Nix feature 'nix-command' is disabled` on a machine whose
  nix.conf does not enable it: the wrapper passed the flag to the outer `nix
  run`, but the app's own `nix eval` call did not. It does now, so the
  catalog can be regenerated with a stock Nix install.

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
