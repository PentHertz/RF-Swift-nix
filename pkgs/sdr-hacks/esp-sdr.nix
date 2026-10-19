# ESP-SDR (ESPARGOS): ESP32-family Wi-Fi/BLE radios as SDRs. Matches
# RF-Swift-images' espsdr_sdrhacks_install (sdr_hacks), host side:
#
#   * espsdr_s3_ring and espsdr_check_spectrum, the repository's host tools for
#     the ESP32-S3 continuous modes;
#   * espsdr-fetch-firmware DIR: the images' mirror of the official prebuilt
#     firmware set (the web flasher's manifest, every part sha256-checked) with
#     an esptool flash.sh per board. The images run it at build time; here it
#     runs on demand, because those files are republished under the same URLs
#     with each release and cannot be pinned in the store;
#   * the ESP-IDF project itself in share/esp-sdr, to build with espressif/idf.
#
# esp-sdr-bridge and SoapyESPSDR are packaged separately.
{ lib, stdenvNoCC, fetchFromGitHub, makeWrapper, python3, writeText }:

let
  python = python3.withPackages (ps: [ ps.numpy ps.pyserial ]);
  # RF-Swift-images' sdr_hacks.sh fetch_firmware.py, unchanged apart from the
  # default output directory.
  fetchFirmware = writeText "fetch_firmware.py" ''
    #!/usr/bin/env python3
    """Mirror the ESP-SDR prebuilt firmware (official web flasher) and write esptool flash scripts.
    Usage: espsdr-fetch-firmware [OUTDIR]   (default $XDG_DATA_HOME/esp-sdr-firmware; re-run to
    refresh; base URL via ESPSDR_FW_BASE)"""
    import hashlib, json, os, sys, urllib.request
    BASE = os.environ.get("ESPSDR_FW_BASE", "https://espargos.net/espsdr/app/firmware")
    default = os.path.join(os.environ.get("XDG_DATA_HOME") or os.path.expanduser("~/.local/share"),
                           "esp-sdr-firmware")
    out = sys.argv[1] if len(sys.argv) > 1 else default
    def get(url):
        # espargos.net answers 403 to Python's default User-Agent
        req = urllib.request.Request(url, headers={"User-Agent": "rfswift-espsdr-fetch/1.0"})
        with urllib.request.urlopen(req, timeout=60) as r:
            return r.read()
    manifest = json.loads(get(BASE + "/manifest.json"))
    for vid, v in manifest["variants"].items():
        d = os.path.join(out, vid)
        os.makedirs(d, exist_ok=True)
        args = []
        for p in v["parts"]:
            data = get(f"{BASE}/{vid}/{p['name']}")
            if hashlib.sha256(data).hexdigest() != p["sha256"]:
                raise SystemExit(f"sha256 mismatch: {vid}/{p['name']}")
            with open(os.path.join(d, p["name"]), "wb") as f:
                f.write(data)
            args += [hex(p["offset"]), p["name"]]
        fs, ea = v["flash_settings"], v["esptool_args"]
        script = os.path.join(d, "flash.sh")
        with open(script, "w") as f:
            f.write("#!/bin/sh\n# " + v.get("label", vid) + "\n# usage: ./flash.sh [/dev/ttyACM0]\n"
                    'cd "$(dirname "$0")"\n'
                    f'exec esptool --chip {ea["chip"]} --port "''${{1:-/dev/ttyACM0}}" '
                    f'--before {ea["before"]} --after {ea["after"]} write-flash '
                    f'-fm {fs["flash_mode"]} -fs {fs["flash_size"]} -ff {fs["flash_freq"]} '
                    + " ".join(args) + "\n")
        os.chmod(script, 0o755)
        print(f"{vid}: {v.get('label')} @ {v.get('version', '?')[:12]}")
    with open(os.path.join(out, "manifest.json"), "w") as f:
        json.dump(manifest, f, indent=1)
    print(f"firmware in {out}")
  '';
in
stdenvNoCC.mkDerivation {
  pname = "esp-sdr";
  version = "0-unstable-2026-10-17";

  src = fetchFromGitHub {
    owner = "ESPARGOS";
    repo = "esp-sdr";
    rev = "f86da81807b7f6e850742f6b789d9468c190ad41";
    hash = "sha256-e3eMuC9AomPrjrUT9k7/4+1xVJpb6j0x/EuSeIPLz00=";
  };

  nativeBuildInputs = [ makeWrapper ];
  dontConfigure = true;
  dontBuild = true;

  installPhase = ''
    runHook preInstall
    mkdir -p $out/share
    cp -r . $out/share/esp-sdr
    makeWrapper ${python.interpreter} $out/bin/espsdr_s3_ring \
      --add-flags $out/share/esp-sdr/tools/s3_ring.py
    makeWrapper ${python.interpreter} $out/bin/espsdr_check_spectrum \
      --add-flags $out/share/esp-sdr/tools/check_spectrum.py
    install -Dm644 ${fetchFirmware} $out/libexec/esp-sdr/fetch_firmware.py
    makeWrapper ${python3.interpreter} $out/bin/espsdr-fetch-firmware \
      --add-flags "-I $out/libexec/esp-sdr/fetch_firmware.py"
    runHook postInstall
  '';

  meta = {
    description = "ESP32-family radios as SDRs: ESP-SDR host tools, firmware mirror and ESP-IDF sources";
    homepage = "https://github.com/ESPARGOS/esp-sdr";
    license = lib.licenses.gpl3Only;
    platforms = lib.platforms.unix;
    mainProgram = "espsdr_s3_ring";
  };
}
