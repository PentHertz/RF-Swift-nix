# RF Swift's own package set: the PentHertz / HydraSDR forks and the
# source-built (or binary-wrapped) tools that are not in nixpkgs.
#
# These take priority over a nixpkgs attribute of the same name when an
# environment lists them (see flake.nix resolvePkg).
#
# Hash pinning: derivations that fetch new sources use `lib.fakeHash` as a
# placeholder. Build once with `nix build .#pkg-<name>`; Nix prints the real
# hash, paste it in. See pkgs/README.md.
# py310 is a python310 package set (from an older nixpkgs) for the few tools
# that require Python 3.10 (Mirage, bluing). It may be null on systems where
# that pin is unavailable, in which case those tools are simply omitted.
{ pkgs, py310 ? null }:

let
  # Proprietary vendor SDKs (SignalHound, Harogic). Computed up front so urh-ng
  # can build its device backends against them.
  vendor = import ./vendor { inherit pkgs; };
in
with pkgs;

# `rec` so tools can depend on one another (e.g. dumpvdl2 -> libacars).
(rec {
  ## --- ADS-B / ACARS / VDL / HFDL (source builds) -----------------------
  libacars = callPackage ./libacars.nix { };
  readsb = callPackage ./readsb.nix { };
  dumpvdl2 = callPackage ./dumpvdl2.nix { inherit libacars; };
  dumphfdl = callPackage ./dumphfdl.nix { inherit libacars; };

  ## --- HydraSDR device library (dependency of the HydraSDR forks) --------
  libhydrasdr = callPackage ./libhydrasdr.nix { };

  ## --- SDR utilities (source builds) ------------------------------------
  cyberether = callPackage ./cyberether { };
  retrogram-soapysdr = callPackage ./retrogram-soapysdr.nix { };
  gqrx-scanner = callPackage ./gqrx-scanner.nix { };
  osmo-fl2k = callPackage ./osmo-fl2k.nix { };
  libresdr-firmware = callPackage ./libresdr-firmware.nix { };
  ais-catcher = callPackage ./ais-catcher.nix { };

  ## --- Hardware (PentHertz DSView .deb, opt-in) -------------------------
  dsview = libsForQt5.callPackage ./dsview.nix { };
  saleae-logic2 = callPackage ./saleae-logic2.nix { };
  hydranfc-sniffer-decoder = callPackage ./hydranfc-decoder.nix { };
  kc908 = callPackage ./kc908.nix { };

  ## --- OpenSSL 1.1 (resurrected for the legacy hostapd WiFi tools) -------
  openssl_1_1 = callPackage ./openssl_1_1.nix { };

  ## --- RFID (container-aligned Proxmark3 + Proxmark5) -------------------
  proxmark3 = callPackage ./proxmark3.nix { proxmark3Base = pkgs.proxmark3; };
  proxmark5 = callPackage ./proxmark5.nix { };

  ## --- Telecom: OpenBTS 2G/3G + deps -----------------------------------
  liba53 = callPackage ./liba53.nix { };
  asn1c-0923 = callPackage ./asn1c-0923.nix { };
  openbts = callPackage ./openbts.nix { inherit liba53; ortp = pkgs.linphonePackages.ortp; bctoolbox = pkgs.linphonePackages.bctoolbox; };
  openbts-umts = callPackage ./openbts-umts.nix { ortp = pkgs.linphonePackages.ortp; bctoolbox = pkgs.linphonePackages.bctoolbox; asn1c = asn1c-0923; };

  ## --- Reverse engineering (latest upstream release) --------------------
  ghidra-latest = callPackage ./ghidra-latest.nix { };
  # Keep the catalog's familiar `ghidra` name while overriding nixpkgs with
  # RF Swift's pinned latest official release.
  ghidra = ghidra-latest;
  joern = callPackage ./joern.nix { };
  unblob = callPackage ./unblob.nix { };
  angr = callPackage ./angr.nix { };
  # Use upstream's preferred WoW64 package. Unlike the deprecated
  # wineWowPackages variant this is served by cache.nixos.org for our pin,
  # avoiding a large local Wine build when realising `reversing`.
  x64dbg = callPackage ./x64dbg.nix { wine = pkgs.wineWow64Packages.stable; };
  ollydbg = callPackage ./ollydbg.nix { wine = pkgs.wineWow64Packages.stable; };
  pwndbg = callPackage ./pwndbg.nix { };

  ## --- GNU Radio OOT modules (source builds) + bundled gnuradio ----------
  gr-rds = callPackage ./oot/gr-rds.nix { };
  gr-iridium = callPackage ./oot/gr-iridium.nix { };
  gr-satellites = callPackage ./oot/gr-satellites.nix { };
  gr-gsm = callPackage ./oot/gr-gsm.nix { inherit gr-osmosdr-penthertz; };
  gr-ais = callPackage ./oot/gr-ais.nix { };
  gr-limesdr = callPackage ./oot/gr-limesdr.nix { };
  gr-tempest = callPackage ./oot/gr-tempest.nix { };
  gr-dab = callPackage ./oot/gr-dab.nix { };
  tetra-kit = callPackage ./tetra-kit.nix { };
  op25 = callPackage ./op25.nix { inherit gr-osmosdr-penthertz; };
  ice9-bluetooth-sniffer = callPackage ./ice9-bluetooth-sniffer.nix { };
  # More OOT modules (the set RF Swift ships), all GNU Radio 3.10.
  gr-foo = callPackage ./oot/gr-foo.nix { };
  gr-adsb = callPackage ./oot/gr-adsb.nix { };
  gr-paint = callPackage ./oot/gr-paint.nix { };
  gr-dect2 = callPackage ./oot/gr-dect2.nix { };
  gr-nfc = callPackage ./oot/gr-nfc.nix { };
  gr-air-modes = callPackage ./oot/gr-air-modes.nix { };
  gr-ieee802-11 = callPackage ./oot/gr-ieee802-11.nix { inherit gr-foo; };
  gr-ieee802-15-4 = callPackage ./oot/gr-ieee802-15-4.nix { inherit gr-foo; };

  # The remaining OOT modules RF Swift ships by default (see RF-Swift-images
  # scripts/gr_oot_modules.sh). All GNU Radio 3.10; pinned rev+hash. A few carry
  # source deps not in nixpkgs (itpp, turbofec, libspectranstream) and are wired
  # against locally-packaged deps below or left as documented gaps.
  gr-lora = callPackage ./oot/gr-lora.nix { };
  gr-inspector = callPackage ./oot/gr-inspector.nix { };
  gr-uaslink = callPackage ./oot/gr-uaslink.nix { };
  gr-X10 = callPackage ./oot/gr-X10.nix { };
  gr-gfdm = callPackage ./oot/gr-gfdm.nix { };
  gr-aaronia_rtsa = callPackage ./oot/gr-aaronia_rtsa.nix { inherit libspectranstream; };
  gr-aistx = callPackage ./oot/gr-aistx.nix { };
  gr-dvbs2 = callPackage ./oot/gr-dvbs2.nix { };
  gr-ieee802-11ah = callPackage ./oot/gr-ieee802-11ah.nix { inherit gr-foo; };
  gr-ieee80211 = callPackage ./oot/gr-ieee80211.nix { };
  gr-droneid = callPackage ./oot/gr-droneid.nix { inherit turbofec crcpp; };
  gr-keyfob = callPackage ./oot/gr-keyfob.nix { };
  gr-radar = callPackage ./oot/gr-radar.nix { };
  gr-nordic = callPackage ./oot/gr-nordic.nix { };
  gr-pdu_utils = callPackage ./oot/gr-pdu_utils.nix { };
  gr-timing_utils = callPackage ./oot/gr-timing_utils.nix { inherit gr-pdu_utils gr-sandia_utils; };
  gr-sandia_utils = callPackage ./oot/gr-sandia_utils.nix { inherit gr-pdu_utils; };
  gr-fhss_utils = callPackage ./oot/gr-fhss_utils.nix { inherit gr-pdu_utils gr-timing_utils; };
  gr-zwave_poore = callPackage ./oot/gr-zwave_poore.nix { };
  gr-mixalot = callPackage ./oot/gr-mixalot.nix { inherit itpp; };
  gr-reveng = callPackage ./oot/gr-reveng.nix { };
  gr-DCF77_Receiver = callPackage ./oot/gr-DCF77_Receiver.nix { };
  gr-j2497 = callPackage ./oot/gr-j2497.nix { };
  gr-m17 = callPackage ./oot/gr-m17.nix { };
  gr-grnet = callPackage ./oot/gr-grnet.nix { };
  gr-aoa = callPackage ./oot/gr-aoa.nix { };
  gr-correctiq = callPackage ./oot/gr-correctiq.nix { };
  gr-dsd = callPackage ./oot/gr-dsd.nix { inherit itpp; };
  gr-nrsc5 = callPackage ./oot/gr-nrsc5.nix { fdk_aac = fdk-aac-hdc; };
  gr-ntsc-rc = callPackage ./oot/gr-ntsc-rc.nix { };
  gr-mer = callPackage ./oot/gr-mer.nix { };
  gr-flarm = callPackage ./oot/gr-flarm.nix { inherit turbofec; };
  gr-guiextra = callPackage ./oot/gr-guiextra.nix { };
  gr-rftap = callPackage ./oot/gr-rftap.nix { };
  gr-radio_astro = callPackage ./oot/gr-radio_astro.nix { };
  gr-cessb = callPackage ./oot/gr-cessb.nix { };

  # Source deps not in nixpkgs, needed by a few OOT modules.
  itpp = callPackage ./itpp.nix { };
  turbofec = callPackage ./turbofec.nix { };
  crcpp = callPackage ./crcpp.nix { };
  libspectranstream = callPackage ./libspectranstream.nix { };
  fdk-aac-hdc = callPackage ./fdk-aac-hdc.nix { };

  gnuradio-rfswift = callPackage ./gnuradio-rfswift.nix {
    inherit gr-osmosdr-penthertz gr-rds gr-iridium gr-satellites gr-gsm
      gr-ais gr-limesdr gr-tempest gr-dab
      gr-foo gr-adsb gr-paint gr-dect2 gr-nfc gr-air-modes
      gr-ieee802-11 gr-ieee802-15-4
      gr-lora gr-inspector gr-uaslink gr-X10 gr-gfdm gr-aaronia_rtsa gr-aistx
      gr-dvbs2 gr-ieee802-11ah gr-ieee80211 gr-droneid gr-keyfob gr-radar
      gr-nordic gr-pdu_utils gr-timing_utils gr-sandia_utils gr-fhss_utils
      gr-zwave_poore gr-mixalot gr-reveng gr-j2497 gr-m17
      gr-grnet gr-aoa gr-correctiq gr-dsd gr-nrsc5 gr-ntsc-rc gr-mer gr-flarm
      gr-guiextra gr-rftap gr-radio_astro gr-cessb;
  };
  gnuradio-rfswift-light = callPackage ./gnuradio-rfswift-light.nix {
    inherit gr-osmosdr-penthertz;
  };

  ## --- PentHertz / HydraSDR forks (compiled from source) ----------------
  # RF Swift ships forks of these upstreams; we build them by overriding the
  # nixpkgs derivation's source, so we inherit its build recipe and deps.
  gr-osmosdr-penthertz = callPackage ./gr-osmosdr-penthertz.nix { inherit libhydrasdr; };
  inspectrum-hydrasdr = callPackage ./inspectrum-hydrasdr.nix { };
  sdrpp-hydrasdr = callPackage ./sdrpp-hydrasdr.nix { inherit libhydrasdr; };
  luaradio-hydrasdr = callPackage ./luaradio-hydrasdr.nix { };

  ## --- Telecom (source Python) -----------------------------------------
  pysim = callPackage ./pysim.nix { };
  modmobmap = callPackage ./modmobmap.nix { };
  scat = callPackage ./sec/scat.nix { };
  sigploit = callPackage ./sec/sigploit.nix { inherit pysctp; };
  osmo-trx = callPackage ./osmo-trx.nix { };
  ocudu = callPackage ./ocudu.nix { };
  mmt-dpi = callPackage ./mmt-dpi.nix { };
  yatebts = callPackage ./yatebts.nix { };
  "5greplay" = callPackage ./5greplay.nix { inherit mmt-dpi; };
  cryptomobile = callPackage ./cryptomobile.nix { };
  pysctp = callPackage ./pysctp.nix { };
  sysmo-usim-tool = callPackage ./sysmo-usim-tool.nix { };
  # nixpkgs' pycrate test runner ignores a failed SEDebugMux test even though
  # that module imports crcmod at runtime. Repair the dependency and make that
  # formerly missed module part of the import gate.
  "python3Packages.pycrate" = pkgs.python3Packages.pycrate.overridePythonAttrs (old: {
    dependencies = (old.dependencies or [ ]) ++ [
      pkgs.python3Packages.crcmod
      pkgs.python3Packages.cryptography
    ];
    pythonImportsCheck = (old.pythonImportsCheck or [ ]) ++ [ "pycrate_osmo.SEDebugMux" ];
  });

  ## --- RFID / NFC (source) ---------------------------------------------
  mfdread = callPackage ./mfdread.nix { };
  chameleon-ultra-cli = callPackage ./chameleon-ultra-cli.nix { };
  mphidflash = callPackage ./mphidflash.nix { libusb-compat = pkgs.libusb-compat-0_1; };
  crypto1-bs = callPackage ./crypto1-bs.nix { };
  milazycracker = callPackage ./milazycracker.nix { inherit crypto1-bs; };
  rfidler = callPackage ./rfidler.nix { inherit mphidflash; };
  nfc-laboratory = callPackage ./nfc-laboratory.nix { inherit libhydrasdr; };

  ## --- Automotive / CAN (source) ---------------------------------------
  caringcaribou = callPackage ./sec/caringcaribou.nix { };
  v2ginjector = callPackage ./sec/v2ginjector.nix { };
  cantact = callPackage ./cantact.nix { };

  ## --- Android / network (source Python) -------------------------------
  drozer = callPackage ./sec/drozer.nix { jdk = pkgs.jdk; };
  smali = callPackage ./smali.nix { };
  autorecon = callPackage ./sec/autorecon.nix { };
  mobsf = callPackage ./mobsf { };

  ## --- Wi-Fi rogue-AP / WPA3 (source Python) ---------------------------
  macstealer = callPackage ./sec/macstealer.nix { };
  pyrit = callPackage ./sec/pyrit.nix { python3Packages = pkgs.python311Packages; };
  roguehostapd = callPackage ./sec/roguehostapd.nix { inherit openssl_1_1; };
  wifiphisher = callPackage ./sec/wifiphisher.nix { inherit roguehostapd openssl_1_1; };
  eaphammer = callPackage ./sec/eaphammer.nix { inherit openssl_1_1; };
  krackattacks-scripts = callPackage ./sec/krackattacks.nix { inherit openssl_1_1; };
  dragonslayer = callPackage ./sec/dragonslayer.nix { inherit openssl_1_1; };
  dragondrain-and-time = callPackage ./sec/dragondrain.nix { };
  dragonforce = callPackage ./sec/dragonforce.nix { };
  fluxion = callPackage ./sec/fluxion.nix { };
  fern-wifi-cracker = callPackage ./sec/fern-wifi-cracker.nix { reaver = pkgs.reaverwps-t6x; };
  wacker = callPackage ./sec/wacker.nix { };
  wifipumpkin3 = callPackage ./sec/wifipumpkin3.nix { };
  sparrow-wifi = callPackage ./sec/sparrow-wifi.nix { };

  ## --- OSINT / recon extra (source Python) -----------------------------
  toutatis = callPackage ./sec/toutatis.nix { };
  finalrecon = callPackage ./sec/finalrecon.nix { };
  sniffle = callPackage ./sec/sniffle.nix { };

  ## --- More security tools (source) ------------------------------------
  mfterm = callPackage ./sec/mfterm.nix { };
  socketcand = callPackage ./sec/socketcand.nix { };
  lsassy = callPackage ./sec/lsassy.nix { };
  bloodyad = callPackage ./sec/bloodyad.nix { };

  ## --- Web / network exploitation (source Python) ----------------------
  sstimap = callPackage ./sec/sstimap.nix { };
  ssrfmap = callPackage ./sec/ssrfmap.nix { };
  sslyze = callPackage ./sec/sslyze.nix { };
  sippts = callPackage ./sec/sippts.nix { };
  hetty = callPackage ./hetty.nix { };

  ## --- OSINT / recon (source Python) -----------------------------------
  sublist3r = callPackage ./sublist3r.nix { };
  spiderfoot = callPackage ./spiderfoot.nix { };

  ## --- Bluetooth / wireless Python tools (default python) ---------------
  whad = callPackage ./whad.nix { };
  nordic-nrf-sniffer = callPackage ./nordic-nrf-sniffer.nix { };
  esp32-bt-classic-sniffer = callPackage ./esp32-bt-sniffer.nix { };
  caeruleus = callPackage ./sec/caeruleus.nix { };
  blueducky = callPackage ./sec/blueducky.nix { };
  bluesploit = callPackage ./sec/bluesploit.nix { };
  whisperpair = callPackage ./sec/whisperpair.nix { };

  # Universal Radio Hacker, PentHertz "urh-ng" fork. Compiled from source, with
  # the HydraSDR / Harogic / SignalHound device libraries so its extra native
  # device backends build (they show as "missing driver" in URH otherwise).
  urh-ng = callPackage ./urh-ng.nix {
    inherit libhydrasdr;
    inherit (vendor) signalhound-sdk harogic-htra-sdk;
  };
})
## --- Proprietary vendor binaries (SignalHound SDK/Spike, Harogic SDK) -------
# Merged in so they are reachable as `pkg-signalhound-sdk`, etc.
// vendor
## --- Python 3.10 tools (Mirage, bluing), built against the py310 pin -------
// (lib.optionalAttrs (py310 != null) {
  mirage = py310.python310Packages.callPackage ./mirage.nix { };
  bluing = py310.python310Packages.callPackage ./bluing.nix {
    stdeb = py310.python310Packages.callPackage ./stdeb.nix { };
  };
})
