# BLERP (FlUxIuS/blerp): the BLE Re-Pairing Attacks PoC (NDSS'26). It has two
# parts: prebuilt nRF firmware images (bleshell/blehci, flashed to the attack
# radio) and a Python MitM host (python-host/mitm.py) that talks to it.
#
# The host depends on a *custom Scapy fork* (github.com/sacca97/scapy), which is
# why upstream and RF-Swift-images run it from an isolated venv rather than the
# system Scapy. Packaging that fork as a fixed Nix derivation is not worth it
# for a fast-moving research PoC, so - as agreed - the `blerp-mitm` launcher
# uses `uv` to build the venv from python-host/requirements.txt at first run
# (uv caches it under ~/.cache/uv afterwards). That means the first invocation
# needs network access to fetch the Scapy fork and the cffi/cryptography wheels;
# everything else (the firmware, the source, the runtime tools) is pinned here.
{ lib, stdenv, fetchFromGitHub, fetchurl, makeWrapper, uv, python3, git, bluez
, tio, cacert }:

let
  fw = name: hash: fetchurl {
    url = "https://github.com/FlUxIuS/blerp/releases/download/v1.0.0/${name}";
    inherit hash;
  };
  firmware = {
    "blehci-v1.0.0.elf"   = fw "blehci-v1.0.0.elf"   "sha256-wdVwsY7Xu4huJSypxcxFXtEyyNr9D0RVsF0SCt3nVZs=";
    "blehci-v1.0.0.hex"   = fw "blehci-v1.0.0.hex"   "sha256-ECYQCrQf0bqNcjS5z0MtzFUYcJadrw8o13W7RdgMZ7w=";
    "blehci-v1.0.0.img"   = fw "blehci-v1.0.0.img"   "sha256-HWK6RNNUvZU0xENYmD2Ekc+0m7XyKTm8gWV5OLI9t4A=";
    "bleshell-v1.0.0.elf" = fw "bleshell-v1.0.0.elf" "sha256-osMyb61dN0ZwuVM1XQ1e+ZRw6uXHYiduixTTeg5/Tz8=";
    "bleshell-v1.0.0.hex" = fw "bleshell-v1.0.0.hex" "sha256-U8NeOltbC/AayxRqCcV5h47EmyNycMTVnYtmSH8vRRk=";
    "bleshell-v1.0.0.img" = fw "bleshell-v1.0.0.img" "sha256-Uewc6OuRDeyP678Hj5kT6k3ZvOhPVHHjB3n72xxBOv8=";
  };
in
stdenv.mkDerivation {
  pname = "blerp";
  version = "1.0.0-unstable-2026-08-30";

  src = fetchFromGitHub {
    owner = "FlUxIuS";
    repo = "blerp";
    rev = "e879a7a5fa18af111583fdb42b33c32e69ec57ee";
    hash = "sha256-tnctw+bY1pUSoVJay3p04Zp0WQmcCa2tPQeRENwJtPI=";
  };

  nativeBuildInputs = [ makeWrapper ];
  dontBuild = true;

  installPhase = ''
    runHook preInstall
    mkdir -p $out/share/blerp $out/share/blerp/firmware $out/bin
    cp -r . $out/share/blerp/
    ${lib.concatStringsSep "\n" (lib.mapAttrsToList
      (name: drv: "install -Dm444 ${drv} $out/share/blerp/firmware/${name}")
      firmware)}

    # uv builds the venv (custom Scapy fork + cffi/cryptography) on first run and
    # caches it. --python points uv at this Nix interpreter so it downloads no
    # Python; git/tio/BlueZ are the runtime helpers. mitm.py imports its sibling
    # modules, so run it from python-host.
    makeWrapper ${uv}/bin/uv $out/bin/blerp-mitm \
      --chdir "$out/share/blerp/python-host" \
      --add-flags "run --no-project --python ${python3}/bin/python3" \
      --add-flags "--with-requirements $out/share/blerp/python-host/requirements.txt" \
      --add-flags "python $out/share/blerp/python-host/mitm.py" \
      --prefix PATH : "${lib.makeBinPath [ git bluez tio ]}" \
      --set-default UV_PYTHON_DOWNLOADS never \
      --set-default SSL_CERT_FILE "${cacert}/etc/ssl/certs/ca-bundle.crt" \
      --set-default GIT_SSL_CAINFO "${cacert}/etc/ssl/certs/ca-bundle.crt"
    runHook postInstall
  '';

  meta = {
    description = "BLERP: BLE Re-Pairing Attacks PoC (firmware + Python MitM host via uv)";
    homepage = "https://github.com/FlUxIuS/blerp";
    license = lib.licenses.mit;
    platforms = lib.platforms.linux;
    mainProgram = "blerp-mitm";
  };
}
