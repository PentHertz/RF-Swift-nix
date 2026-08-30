# gps-sdr-sim: GPS-SDR-SIM, generates GPS L1 baseband I/Q samples for SDR
# transmitters (osqzss). Matches RF-Swift-images' gps_sdr_sim_soft_install:
# one C file built by the upstream Makefile plus the UHD/bladeRF helper scripts.
{ lib, stdenv, fetchFromGitHub, python3 }:

stdenv.mkDerivation {
  pname = "gps-sdr-sim";
  version = "unstable-2025";

  src = fetchFromGitHub {
    owner = "osqzss";
    repo = "gps-sdr-sim";
    rev = "28ca29a6719475195e3aabd5930c4ed02d67190f";
    hash = "sha256-qr36zSX7n3NmSU2WnN6AqmREmBolxHnAN0xA/iCkhmY=";
  };

  # The Makefile hardcodes CC=gcc and SHELL=/bin/bash; use the stdenv compiler
  # (clang on Darwin) and the sandbox bash.
  makeFlags = [ "CC=${stdenv.cc.targetPrefix}cc" "SHELL=${stdenv.shell}" ];

  installPhase = ''
    runHook preInstall
    install -Dm755 gps-sdr-sim $out/bin/gps-sdr-sim
    # UHD transmit helper (needs the uhd python module at runtime, provided by
    # the SDR environments' uhd package); keep the original name like the image.
    install -Dm755 gps-sdr-sim-uhd.py $out/bin/gps-sdr-sim-uhd.py
    substituteInPlace $out/bin/gps-sdr-sim-uhd.py \
      --replace-quiet "#!/usr/bin/env python" "#!${python3.interpreter}" \
      --replace-quiet "#!/usr/bin/python" "#!${python3.interpreter}"
    # Sample ephemeris + motion files and the bladeRF script, for the README
    # examples.
    mkdir -p $out/share/gps-sdr-sim
    cp -r brdc*.??n *.csv bladerf.script $out/share/gps-sdr-sim/ 2>/dev/null || true
    runHook postInstall
  '';

  meta = {
    description = "GPS-SDR-SIM: software-defined GPS signal simulator (L1 C/A baseband I/Q)";
    homepage = "https://github.com/osqzss/gps-sdr-sim";
    license = lib.licenses.mit;
    mainProgram = "gps-sdr-sim";
    platforms = lib.platforms.unix;
  };
}
