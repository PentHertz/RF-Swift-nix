# RF Swift - Nix environment catalog (single source of truth)
#
# Each entry maps an RF Swift "image" to a set of nixpkgs packages that
# reproduce - as closely as nixpkgs allows - the tools that image installs in
# the Docker world. Package strings are attribute paths into `pkgs`
# (dot-separated, e.g. "python3Packages.impacket").
#
# This file is PURE DATA - no reference to `pkgs` - so it is consumed both by
# flake.nix (to build devShells / profiles) and by gen-catalog.nix (to emit the
# catalog.json the RF Swift binary reads). After editing, run
# `nix run .#gen-catalog` to refresh catalog.json.
#
# `missing` lists tools with no nixpkgs equivalent yet (upstream-only, PentHertz
# / HydraSDR forks, or vendor blobs). They are documented here for transparency
# rather than silently dropped. flake.nix also drops, with a build-time trace,
# any listed package that is unavailable on a given platform, so one missing
# tool never breaks the whole shell.
{
  ######################################################################
  # SDR
  ######################################################################
  sdr_light = {
    description = "Light SDR set: GNU Radio, everyday SDR apps and the full device/driver layer (sdrsa_devices).";
    category = "SDR";
    prerequisites = [
      "soapysdr-with-plugins"
      "soapyplutosdr"
      "soapyremote"
      "soapyuhd"
      "soapybladerf"
      "rtl-sdr-osmocom"
      "hackrf"
      "airspy"
      "airspyhf"
      "limesuite"
      "uhd"
      "libbladeRF"
      "libhydrasdr"
      "libiio"
      "libad9361"
      "osmo-fl2k"
      "libresdr-firmware"
      "signalhound-sdk"
      "harogic-htra-sdk"
      # Device stacks the sdrsa_devices image builds from source.
      "libxtrx"
      "librfnm"
      "litex-m2sdr"
      "usdr-lib"
    ];
    packages = [
      # SoapySDR + all its device plugins (rtlsdr, hackrf, uhd, airspy, bladerf, lime, plutosdr, remote, ...)
      "soapysdr-with-plugins"
      "soapyplutosdr"
      "soapyremote"
      "soapyuhd"
      "soapybladerf"
      # Device drivers inherited from sdrsa_devices
      "rtl-sdr-osmocom"
      "hackrf"
      "airspy"
      "airspyhf"
      "limesuite"
      "uhd"
      "libbladeRF"
      "libhydrasdr"
      "libiio"
      "libad9361"
      "osmo-fl2k"
      "libresdr-firmware"
      "signalhound-sdk"
      "harogic-htra-sdk"
      # Device stacks the sdrsa_devices image builds from source: XTRX (with
      # SoapyXTRX), RFNM (+ SoapyRFNM), LiteX M2SDR, uSDR, FUNcube (qthid GUI;
      # gr-funcube is bundled into GNU Radio) and SoapyHydraSDR. The Soapy
      # modules are also wired into soapysdr-with-plugins (pkgs/default.nix).
      "libxtrx"
      "librfnm"
      "soapy-rfnm"
      "soapyhydrasdr"
      "litex-m2sdr"
      "usdr-lib"
      "qthid"
      # GNU Radio is after the device layer; OOT modules are bundled in it so
      # GRC discovers them from the same prefix.
      "gnuradio-rfswift-light"
      # End-user applications. The PentHertz/HydraSDR forks and the source-only
      # decoders below are compiled from source (see pkgs/).
      "gqrx"
      "sdrpp-hydrasdr"
      "cubicsdr"
      "inspectrum-hydrasdr"
      "urh-ng"
      "multimon-ng"
      "rtl_433"
      "hydrasdr433"
      "kalibrate-hydrasdr"
      "dump1090-fa"
      "readsb"
      "dumpvdl2"
      "dumphfdl"
      "retrogram-soapysdr"
      "gqrx-scanner"
      "sdrangel"
      "luaradio-hydrasdr"
      "gnss-sdr"
      "nanovna-saver"
      "nanovna-qt"
      "librevna"
      "xnec2c"
      "jupyter"
      "kc908"
      "signalhound-spike"
      "signalhound-vsg60"
      "sastudio"
    ];
    # Remaining device modules present in the image scripts but not yet
    # reproducibly packaged for Nix are explicit rather than silently claimed.
    missing = [
      "SoapyHarogic"
      "XTRX / LiteX M2SDR / uSDR PCIe kernel modules (host drivers; the userspace stacks are packaged)"
      "SDRplay API / SoapySDRPlay (nixpkgs 3.15.1 source URL currently returns 404)"
      "gr-htra"
      "gr-signalhound"
      "Leo Bodnar LBE-1420/1421 tools"
      "gnsslogger"
      "pocketVNA"
      "LibreCAL"
      "Lotus BUDC tuner"
      # Prebuilt Linux binaries / large Ubuntu-specific installers with no clean
      # source build: not reproducibly packageable for Nix (and Linux-only).
      "KCSDI (Deepace, prebuilt AppImage)"
      "Artemis (prebuilt binary)"
      "FISSURE (RF framework; large pinned pip/apt install into a system venv)"
    ];
  };

  sdr_full = {
    description = "Full SDR arsenal: sdr_light plus SDRangel, SatDump, SigDigger, GQRX and many GNU Radio OOT modules available in nixpkgs.";
    category = "SDR";
    prerequisites = [
      "soapysdr-with-plugins"
      "soapyplutosdr"
      "soapyremote"
      "soapyuhd"
      "soapybladerf"
      "rtl-sdr-osmocom"
      "hackrf"
      "airspy"
      "airspyhf"
      "limesuite"
      "uhd"
      "libbladeRF"
      "libhydrasdr"
      "libiio"
      "libad9361"
      "osmo-fl2k"
      "libresdr-firmware"
      "signalhound-sdk"
      "harogic-htra-sdk"
      # Device stacks the sdrsa_devices image builds from source.
      "libxtrx"
      "librfnm"
      "litex-m2sdr"
      "usdr-lib"
    ];
    packages = [
      "soapysdr-with-plugins"
      "soapyplutosdr"
      "soapyremote"
      "soapyuhd"
      "soapybladerf"
      "rtl-sdr-osmocom"
      "hackrf"
      "airspy"
      "airspyhf"
      "limesuite"
      "uhd"
      "libbladeRF"
      "libhydrasdr"
      "libiio"
      "libad9361"
      "osmo-fl2k"
      "libresdr-firmware"
      "signalhound-sdk"
      "harogic-htra-sdk"
      # Device stacks the sdrsa_devices image builds from source: XTRX (with
      # SoapyXTRX), RFNM (+ SoapyRFNM), LiteX M2SDR, uSDR, FUNcube (qthid GUI;
      # gr-funcube is bundled into GNU Radio) and SoapyHydraSDR. The Soapy
      # modules are also wired into soapysdr-with-plugins (pkgs/default.nix).
      "libxtrx"
      "librfnm"
      "soapy-rfnm"
      "soapyhydrasdr"
      "litex-m2sdr"
      "usdr-lib"
      "qthid"
      # GNU Radio bundled with the extended OOT modules added by sdr_full.
      "gnuradio-rfswift"
      "gqrx"
      "sdrpp-hydrasdr"
      "cubicsdr"
      "inspectrum-hydrasdr"
      "urh-ng"
      "multimon-ng"
      "rtl_433"
      "hydrasdr433"
      "kalibrate-hydrasdr"
      "dump1090-fa"
      "readsb"
      "dumpvdl2"
      "dumphfdl"
      "retrogram-soapysdr"
      "gqrx-scanner"
      "sdrangel"
      "luaradio-hydrasdr"
      "satdump"
      "sigdigger"
      "qsstv"
      "gpredict"
      "ais-catcher"
      "gnss-sdr"
      "nanovna-saver"
      "nanovna-qt"
      "librevna"
      "xnec2c"
      "jupyter"
      "python3Packages.numpy"
      "python3Packages.scikit-learn"
      "python3Packages.pandas"
      # Extra software the sdr_full image adds (scripts/sdr_softwares.sh).
      "nfc-laboratory"
      "ice9-bluetooth-sniffer"
      "qradiolink"
      "gps-sdr-sim"
      "waving-z"
      "pyspecsdr"
      "meshtastic-sdr"
      "python3Packages.meshtastic"
      # Signal Hound + Harogic device SDKs (auto-download from public URLs,
      # unfree, hashes pinned). The Spike GUI is opt-in: pkg-signalhound-spike.
      "trunk-recorder"
      "op25"
      "tetra-kit"
      "signalhound-spike"
      "signalhound-vsg60"
      "sastudio"
      "kc908"
    ];
    # The full GNU Radio OOT set RF Swift ships (RF-Swift-images
    # scripts/gr_oot_modules.sh) is bundled into gnuradio-rfswift and appears in
    # gnuradio-companion. In addition to osmosdr-fork, lora_sdr, gr-difi, fosphor,
    # gr-rds, gr-iridium, gr-satellites, gr-gsm, gr-ais, gr-limesdr, gr-tempest,
    # gr-dab, gr-foo, gr-adsb, gr-paint, gr-dect2, gr-nfc, gr-air-modes,
    # gr-ieee802-11 and gr-ieee802-15-4, this now also bundles: gr-lora,
    # gr-inspector, gr-uaslink, gr-X10, gr-gfdm, gr-aistx, gr-dvbs2,
    # gr-ieee802-11ah, gr-droneid, gr-keyfob, gr-nordic, gr-pdu_utils,
    # gr-timing_utils, gr-sandia_utils, gr-fhss_utils, gr-zwave_poore, gr-mixalot,
    # gr-reveng, gr-j2497, gr-grnet, gr-aoa, gr-correctiq, gr-dsd, gr-ntsc-rc,
    # gr-mer, gr-flarm, gr-guiextra, gr-rftap, gr-radio_astro and gr-cessb.
    # Spike (Signal Hound) and SAStudio (Harogic) are opt-in vendor GUIs: they
    # are packaged (pkg-signalhound-spike / pkg-sastudio) but kept out of the
    # default set because they are large unfree downloads whose hash must be
    # pinned on the first build (do it on a machine with disk headroom).
    # CyberEther is intentionally NOT here: it is a large, memory-hungry Vulkan
    # build that would make the whole sdr_full closure fail (and take a long time)
    # if bundled. It lives in its own dedicated `cyberether` environment instead.
    #
    # One OOT module is not bundled (kept packaged as pkg-gr-DCF77_Receiver):
    #   gr-DCF77_Receiver - upstream ships only Python flowgraphs/tests, with no
    #                       CMake module to build/install into the GNU Radio prefix.
    # Everything else from the reference OOT set now builds and is bundled,
    # including the ones that needed extra work on this nixpkgs pin: gr-nrsc5
    # (against a locally-packaged HDC-patched fdk-aac), gr-m17 (libm17 submodule),
    # gr-aaronia_rtsa (locally-packaged libspectranstream), gr-radar and
    # gr-ieee80211 (UHD/Qt inputs), gr-dsd/gr-mixalot (locally-packaged itpp),
    # gr-flarm/gr-droneid (locally-packaged turbofec/CRCpp).
    missing = [
      "gr-DCF77_Receiver"
      # sdr_full image extras not yet packaged (scripts/sdr_softwares.sh):
      "v2verifier (C++/Boost/OpenSSL + Tk/PIL Python GUI; mixed build not packaged yet)"
      "tetra-kit-player (Node/TypeScript web player; needs an npm dependency lock hash)"
      "osmo-tetra-sq5bpf + libosmo-dsp (tetra_suite; libosmo-dsp not in nixpkgs)"
      "fl2k-examples (osmo-fl2k demo patches/scripts, not standalone tools)"
      "ML/DL extras (tensorflow; the image itself fails on CPython 3.14). numpy/scikit-learn/pandas are included"
      "SoapyHarogic"
      "XTRX / LiteX M2SDR / uSDR PCIe kernel modules (host drivers; the userspace stacks are packaged)"
      "SDRplay API / SoapySDRPlay (nixpkgs 3.15.1 source URL currently returns 404)"
      "gr-htra"
      "gr-signalhound"
      "Leo Bodnar LBE-1420/1421 tools"
      "gnsslogger"
      "pocketVNA"
      "LibreCAL"
      "Lotus BUDC tuner"
      # Prebuilt Linux binaries / large Ubuntu-specific installers with no clean
      # source build: not reproducibly packageable for Nix (and Linux-only).
      "KCSDI (Deepace, prebuilt AppImage)"
      "Artemis (prebuilt binary)"
      "FISSURE (RF framework; large pinned pip/apt install into a system venv)"
    ];
  };

  ######################################################################
  # CyberEther (dedicated, because it is a heavy Vulkan build)
  ######################################################################
  cyberether = {
    description = "CyberEther: heterogeneous SDR signal visualisation (Vulkan), with the SoapySDR device stack.";
    category = "SDR";
    prerequisites = [
      "soapysdr-with-plugins"
      "hackrf"
      "rtl-sdr-osmocom"
      "airspy"
      "limesuite"
      "uhd"
    ];
    packages = [
      # Runtime SDR device support (SoapySDR modules + device tools).
      "soapysdr-with-plugins"
      "hackrf"
      "rtl-sdr-osmocom"
      "airspy"
      "limesuite"
      "uhd"
      "cyberether"
    ];
    # CyberEther is a large Vulkan + shader-toolchain build. It is isolated here
    # so it never blocks other environments. It compiles a few very heavy fmt
    # header-only C++20 translation units (e.g. src/compositor/default/base.cc);
    # on a RAM-constrained host, build it with limited parallelism so cc1plus is
    # not OOM-killed:  nix build .#pkg-cyberether --cores 2  (or --cores 1). It
    # then caches for the environment. Needs a few GB of build disk + RAM.
    missing = [ ];
  };

  ######################################################################
  # RFID / NFC
  ######################################################################
  rfid = {
    description = "RFID / NFC toolkit: Proxmark3 (Iceman), libnfc, MIFARE crackers and NFC utilities.";
    category = "RFID";
    prerequisites = [ "libnfc" "libfreefare" "pcsclite" "ccid" ];
    packages = [
      "libnfc"
      "libfreefare"
      "pcsclite"
      "ccid"
      "proxmark3"
      "proxmark5"
      "mfoc"
      "mfcuk"
      "python3Packages.nfcpy"
      "pcsc-tools"
      "python3Packages.bitstring"
      "mfterm"
      "mfdread"
      "chameleon-ultra-cli"
      "mphidflash"
      "crypto1-bs"
      "milazycracker"
      "rfidler"
      "nfc-laboratory"
    ];
    missing = [ ];
  };

  ######################################################################
  # Wi-Fi (inherits the general network layer)
  ######################################################################
  wifi = {
    description = "Wi-Fi audit suite: aircrack-ng, hcxtools, WPS/WPA3 attacks and rogue-AP frameworks, on top of the network toolkit.";
    category = "WiFi";
    packages = [
      "aircrack-ng"
      "hcxtools"
      "hcxdumptool"
      "mdk4"
      "reaverwps-t6x"
      "bully"
      "pixiewps"
      "cowpatty"
      "wifite2"
      "kismet"
      "bettercap"
      "hostapd"
      "wpa_supplicant"
      "macchanger"
      "dnsmasq"
      "crunch"
      "hashcat"
      "john"
      "wireshark"
      "nmap"
      "iw"
      "ubertooth"
      "airgeddon"
      "airgorah"
      "asleap"
      "hostapd-mana"
      "freeradius"
      "horst"
      "chirp"
      "wacker"
      "wifipumpkin3"
      "sparrow-wifi"
      "macstealer"
      "fluxion"
      "fern-wifi-cracker"
      "wifiphisher"
      "eaphammer"
      "krackattacks-scripts"
      "dragonforce"
      "dragonslayer"
      "dragondrain-and-time"
      "pyrit"
    ];
    missing = [
      "BeEF (Ruby/bundler browser-exploitation framework; run as a service rather than a CLI)"
    ];
  };

  ######################################################################
  # Bluetooth (Classic + BLE), on the SDR device layer
  ######################################################################
  bluetooth = {
    description = "Bluetooth Classic + BLE: BlueZ stack, Ubertooth, and Python BLE tooling, on the SDR device layer.";
    category = "Bluetooth";
    prerequisites = [ "bluez" "libbtbb" "ubertooth" "hackrf" "rtl-sdr-osmocom" ];
    packages = [
      "bluez"
      "bluez-tools"
      "ubertooth"
      "libbtbb"
      "python3Packages.bleak"
      "python3Packages.pybluez"
      "python3Packages.scapy"
      "gnuradio"
      "hackrf"
      "rtl-sdr-osmocom"
      "wireshark"
      # Built from source (Mirage/bluing use a pinned Python 3.10; see pkgs/).
      "mirage"
      "bluing"
      "whad"
      "btlejack"
      "sniffle"
      "ice9-bluetooth-sniffer"
      "caeruleus"
      "blueducky"
      "bluesploit"
      "whisperpair"
      "nordic-nrf-sniffer"
      "esp32-bt-classic-sniffer"
    ];
    missing = [
      "breaktooth / blerp (BreakTooth ships its own bundled tooling; blerp needs a custom Scapy fork plus device firmware)"
    ];
  };

  ######################################################################
  # General network / web pentest
  ######################################################################
  network = {
    description = "General network & web pentest: nmap, Wireshark, Metasploit, bettercap, Kismet, hashcat/john, sqlmap and more.";
    category = "Network";
    packages = [
      "nmap"
      "wireshark"
      "hping"
      "ettercap"
      "metasploit"
      "bettercap"
      "kismet"
      "hashcat"
      "john"
      "sqlmap"
      "netcat-openbsd"
      "tcpdump"
      "tcpreplay"
      "python3Packages.impacket"
      "responder"
      "crunch"
      "sngrep"
      "burpsuite"
      # Web / recon / scanning
      "whatweb"
      "wafw00f"
      "nikto"
      "wpscan"
      "dirb"
      "gobuster"
      "ffuf"
      "feroxbuster"
      "nuclei"
      "httpx"
      "katana"
      "hakrawler"
      "waybackurls"
      "gowitness"
      "arjun"
      "dalfox"
      "commix"
      "xsstrike"
      "wfuzz"
      "graphqlmap"
      "gitleaks"
      "trufflehog"
      # Network scanning / discovery
      "masscan"
      "zmap"
      "rustscan"
      "naabu"
      "amass"
      "subfinder"
      "dnsx"
      "assetfinder"
      "dnstwist"
      "fping"
      "arp-scan"
      "netdiscover"
      "onesixtyone"
      "snmpcheck"
      "sniffnet"
      "trippy"
      "curlie"
      "sipvicious"
      "tcpflow"
      "dsniff"
      # Bruteforce / creds / AD
      "thc-hydra"
      "medusa"
      "ncrack"
      "netexec"
      "evil-winrm"
      "smbmap"
      "enum4linux-ng"
      "kerbrute"
      "certipy"
      "mitm6"
      # Pivoting / proxying / MITM
      "mitmproxy"
      "chisel"
      "ligolo-ng"
      "sshuttle"
      "proxychains-ng"
      "socat"
      "stunnel"
      "proxify"
      "sslscan"
      "tailcat"
      # More web/recon/exploit tooling + resources
      "caido"
      "routersploit"
      "dnsrecon"
      "fierce"
      "gospider"
      "joomscan"
      "testssl"
      "sipp"
      "exploitdb"
      "seclists"
      "payloadsallthethings"
      "enum4linux"
      "autorecon"
      "sstimap"
      "ssrfmap"
      "sippts"
      "hetty"
      "sslyze"
    ];
    missing = [ ];
  };

  ######################################################################
  # Reverse engineering / firmware
  ######################################################################
  reversing = {
    description = "Reverse engineering & firmware analysis: Ghidra, rizin/Cutter, radare2, binwalk, AFL++, semgrep, ImHex.";
    category = "Reversing";
    packages = [
      "ghidra"
      "radare2"
      "rizin"
      "cutter"
      "binwalk"
      "unicorn"
      "keystone"
      "aflplusplus"
      "semgrep"
      "imhex"
      "gdb"
      "cppcheck"
      "clang-tools"
      "yara"
      # Debuggers / exploit dev
      "gef"
      "ropgadget"
      "one_gadget"
      "checksec"
      "capstone"
      "rehex"
      "hexedit"
      # Static analysis / supply chain
      "flawz"
      "trivy"
      "grype"
      "syft"
      "gitleaks"
      # Forensics / firmware
      "volatility3"
      "foremost"
      "testdisk"
      "sleuthkit"
      "autopsy"
      "dc3dd"
      "ddrescue"
      "chntpw"
      "sasquatch"
      "kaitai-struct-compiler"
      "joern"
      "unblob"
      "x64dbg"
      "ollydbg"
      "pwndbg"
      "dsview"
    ];
    # Ghidra itself is present (stable `ghidra`); ghidra-latest is a packaged
    # opt-in (pkg-ghidra-latest) for the newest upstream release, not a gap.
    # The Windows debuggers x64dbg and OllyDBG are shipped Wine-wrapped; pwndbg
    # comes from its official self-contained .deb.
    #
    # angr is a documented gap for this nixpkgs pin: the snapshot ships angr
    # 9.2.193 alongside pycparser 3.00, a major rewrite that removed the PLY
    # parser angr's C-type engine depends on (writable clex.filename, self.cparser,
    # a `parameter_declaration` start symbol), so `import angr` fails outright.
    # The only correct fix is to pin pycparser to 2.x for the environment, but
    # doing so overrides the python package set and busts the binary-cache hits of
    # the whole meson/python-built native stack (gtk4, wine, gdk-pixbuf, pipewire,
    # ...), forcing tens of GiB of from-source rebuilds. pkgs/angr.nix keeps the
    # correct derivation (setuptools-rust, sibling-pin relax, msgspec) so angr
    # returns for free once nixpkgs' angr supports pycparser 3.00 or the flake pin
    # advances; until then it is listed here rather than shipped broken.
    missing = [ "angr" ];
  };

  ######################################################################
  # Hardware hacking
  ######################################################################
  hardware = {
    description = "Hardware hacking: avrdude, sigrok/PulseView, OpenOCD, flashrom, openFPGALoader, esptool, dfu-util.";
    category = "Hardware";
    prerequisites = [ "libsigrok" "libsigrokdecode" "hidapi" ];
    packages = [
      "libsigrok"
      "libsigrokdecode"
      "hidapi"
      "avrdude"
      "dfu-util"
      "sigrok-cli"
      "pulseview"
      "openocd"
      "flashrom"
      "openfpgaloader"
      "esptool"
      "picocom"
      "minicom"
      "arduino-cli"
      "dfu-programmer"
      "gcc-arm-embedded"
      "platformio"
      "stlink"
      "teensy-loader-cli"
      "urjtag"
      "mtkclient"
      "scopehal-apps"
      "dsview"
      "saleae-logic2"
      "hydranfc-sniffer-decoder"
    ];
    missing = [ ];
  };

  ######################################################################
  # Automotive / CAN
  ######################################################################
  automotive = {
    description = "Automotive / CAN bus: can-utils, SavvyCAN, gallia and CAN analysis tooling.";
    category = "Automotive";
    prerequisites = [ "can-utils" "python3Packages.python-can" "python3Packages.cantools" ];
    packages = [
      "can-utils"
      "savvycan"
      "python3Packages.python-can"
      "python3Packages.cantools"
      "gallia"
      "socketcand"
      "caringcaribou"
      "cantact"
      "v2ginjector"
      "wireshark"
    ];
    missing = [ ];
  };

  ######################################################################
  # OSINT
  ######################################################################
  osint = {
    description = "OSINT: theHarvester, sherlock, recon-ng, subfinder, exiftool and reconnaissance tools.";
    category = "OSINT";
    packages = [
      "theharvester"
      "sherlock"
      "recon-ng"
      "subfinder"
      "exiftool"
      "holehe"
      "maigret"
      "instaloader"
      "assetfinder"
      "waybackurls"
      "whois"
      "dnsutils"
      "amass"
      "subfinder"
      "dnsx"
      "dnstwist"
      "photon"
      "gitleaks"
      "trufflehog"
      "gowitness"
      "sublist3r"
      "spiderfoot"
    ];
    missing = [ ];
  };

  ######################################################################
  # Mobile / Android
  ######################################################################
  android = {
    description = "Android / mobile: adb/fastboot, apktool, frida, androguard, scrcpy, jadx and reversing tools.";
    category = "Mobile";
    prerequisites = [ "android-tools" ];
    packages = [
      "android-tools"
      "apktool"
      "scrcpy"
      "jadx"
      "frida-tools"
      "python3Packages.androguard"
      "python3Packages.frida-python"
      "dex2jar"
      "apksigner"
      "aapt"
      "apkeep"
      "apkleaks"
      "enjarify"
      "objection"
      "androguard"
      "drozer"
      "smali"
      "mobsf"
    ];
    missing = [ ];
  };

  ######################################################################
  # Active Directory
  ######################################################################
  ad = {
    description = "Active Directory attack tooling: impacket, NetExec, kerbrute, Samba/LDAP/Kerberos clients.";
    category = "Network";
    packages = [
      "python3Packages.impacket"
      "netexec"
      "kerbrute"
      "samba"
      "openldap"
      "krb5"
      "responder"
      "python3Packages.bloodhound-py"
      "certipy"
      "mitm6"
      "evil-winrm"
      "smbmap"
      "enum4linux-ng"
      "certsync"
      "donpapi"
      "lsassy"
      "bloodyad"
    ];
    missing = [ ];
  };

  ######################################################################
  # Telecom (2G-5G): Osmocom stack, srsRAN, Open5GS, UERANSIM, YATE
  ######################################################################
  telecom = {
    description = "Mobile telecom 2G-5G: Osmocom stack, srsRAN, Open5GS, UERANSIM, YATE and SDR.";
    category = "Telecom";
    prerequisites = [
      "libosmocore"
      "lksctp-tools"
      "soapysdr-with-plugins"
      "uhd"
      "limesuite"
      "hackrf"
      # telecom_5G_bladerf runs the 5G stack on a bladeRF.
      "libbladeRF"
      "soapybladerf"
    ];
    packages = [
      # Protocol and SDR device libraries/drivers precede applications.
      "libosmocore"
      "lksctp-tools"
      "soapysdr-with-plugins"
      "uhd"
      "limesuite"
      "hackrf"
      "libbladeRF"
      "soapybladerf"
      # Core network / RAN
      "srsran"
      "ocudu"
      "open5gs"
      "ueransim"
      "yate"
      # Osmocom 2G/3G stack
      "osmo-bsc"
      "osmo-msc"
      "osmo-hlr"
      "osmo-sgsn"
      "osmo-ggsn"
      "osmo-bts"
      "osmo-pcu"
      "osmo-mgw"
      "osmo-sip-connector"
      # SIM / crypto / utilities
      "python3Packages.pycrate"
      "cryptomobile"
      "pysctp"
      "sysmo-usim-tool"
      "pysim"
      "modmobmap"
      "scat"
      "sigploit"
      "5greplay"
      "yatebts"
      "openbts"
      "openbts-umts"
      "osmo-trx"
      "kalibrate-rtl"
      # telecom_utils / telecom_4Gto5G_extended image extras.
      "bromelia"
      "py5sig"
      "telecom-wireshark-dissectors"
      "nmap"
      "jupyter"
      # Patched training variants; programs carry the variant name
      # (ueransim_nullciph-nr-gnb, Open5GS_nohttp2, Open5GS_0caps, ...).
      "ueransim_nullciph"
      "open5gs_nohttp2"
      "open5gs_0caps"
      # telecom_utils inherits sdr_light in the image build, so retain the
      # light/common GNU Radio module set here as well.
      "gnuradio-rfswift-light"
      "wireshark"
    ];
    # Cellular coverage: 2G/2.5G (Osmocom BSC/MSC/HLR/BTS/PCU + YATE + osmo-trx),
    # 3G (Osmocom SGSN/GGSN), 4G & 5G-NSA (srsRAN), 5G-SA (OCUDU O-CU/O-DU +
    # Open5GS core + UERANSIM). SIM/crypto: pysim, sysmo-usim-tool, CryptoMobile,
    # pycrate, pysctp, SCAT, modmobmap.
    missing = [
      "jss7 (Java SS7 stack, 17-module Maven build; its dependency closure can't be fetched inside the Nix sandbox)"
      "Burp Suite (telecom_4Gto5G_extended; available in the network environment)"
    ];
  };

  telecom_5g_bladerf = {
    description = "5G SA on a bladeRF: srsRAN Project bladeRF fork with its SoapyBladeRF variant, Open5GS core, and the telecom utility set (telecom_5G_bladerf image).";
    category = "Telecom";
    prerequisites = [
      "libbladeRF"
      "soapysdr-with-plugins-bladerf-srsran"
      "uhd"
      "soapyuhd"
      "lksctp-tools"
    ];
    packages = [
      # The bladeRF-specific radio path replaces the stock SoapyBladeRF here;
      # srsRAN Project speaks UHD only, so the bladeRF is reached through
      # SoapyUHD's UHD-side bridge (uhd + soapyuhd).
      "libbladeRF"
      "soapysdr-with-plugins-bladerf-srsran"
      "uhd"
      "soapyuhd"
      "lksctp-tools"
      # 5G SA RAN + core
      "srsran-project-bladerf"
      "open5gs"
      # telecom_utils tools the image inherits
      "python3Packages.pycrate"
      "cryptomobile"
      "pysim"
      "pysctp"
      "sysmo-usim-tool"
      "scat"
      "sigploit"
      "modmobmap"
      "bromelia"
      "py5sig"
      # Analysis extras of the image
      "wireshark"
      "wireshark-cli"
      "telecom-wireshark-dissectors"
      "nmap"
      "jupyter"
    ];
    missing = [
      "jss7 (Java SS7 stack, 17-module Maven build; its dependency closure can't be fetched inside the Nix sandbox)"
    ];
  };
}
