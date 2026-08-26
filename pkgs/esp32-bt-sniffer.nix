# ESP32 Bluetooth Classic sniffer (FlUxIuS): the host-side control tool
# (BTSnifferBREDR.py) that drives an ESP32 flashed with the sniffer firmware.
# The firmware itself is built separately with PlatformIO; this packages the host
# tool so captures work once the ESP32 is flashed.
{ lib, stdenv, fetchFromGitHub, makeWrapper, python3 }:

let
  pyEnv = python3.withPackages (ps: with ps; [ colorama click pyserial scapy ]);
in
stdenv.mkDerivation {
  pname = "esp32-bt-classic-sniffer";
  version = "unstable";

  src = fetchFromGitHub {
    owner = "FlUxIuS";
    repo = "esp32_bluetooth_classic_sniffer";
    rev = "39b7bacdb2d95d9aa37c917bf4b4f51e911b50dc";
    hash = "sha256-t6ywWFNeG/HO5ofvoihgR4oZeKn4337icpRtNtKUrF4=";
  };

  nativeBuildInputs = [ makeWrapper ];
  dontBuild = true;

  installPhase = ''
    runHook preInstall
    mkdir -p $out/share/esp32-bt-sniffer $out/bin
    cp -r . $out/share/esp32-bt-sniffer/
    makeWrapper ${pyEnv}/bin/python3 $out/bin/BTSnifferBREDR \
      --add-flags "$out/share/esp32-bt-sniffer/BTSnifferBREDR.py" \
      --chdir "$out/share/esp32-bt-sniffer" \
      --prefix PYTHONPATH : "$out/share/esp32-bt-sniffer"
    runHook postInstall
  '';

  meta = {
    description = "Host-side control tool for the ESP32 Bluetooth Classic sniffer";
    homepage = "https://github.com/FlUxIuS/esp32_bluetooth_classic_sniffer";
    license = lib.licenses.gpl3Plus;
    platforms = lib.platforms.linux;
    mainProgram = "BTSnifferBREDR";
  };
}
