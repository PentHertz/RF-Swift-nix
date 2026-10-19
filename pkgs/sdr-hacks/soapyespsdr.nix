# SoapyESPSDR (ESPARGOS): the ESP32-S31 streaming firmware of ESP-SDR
# (Ethernet or USB) as a SoapySDR device (driver=espsdr), plus
# espsdr_loss_monitor. Matches RF-Swift-images' soapyespsdr_sdrhacks_install
# (sdr_hacks), udev rule included. The module lands in lib/SoapySDR/modules*,
# which RF Swift puts on SOAPY_SDR_PLUGIN_PATH for every tool of the
# environment.
{ lib, stdenv, fetchFromGitHub, cmake, pkg-config, soapysdr, curl, jsoncpp, libusb1 }:

stdenv.mkDerivation {
  pname = "soapyespsdr";
  version = "0.3.0-unstable-2026-10-17";

  src = fetchFromGitHub {
    owner = "ESPARGOS";
    repo = "SoapyESPSDR";
    rev = "81fe16e89ff31601c746a99ce93b05f6a1d1a2f1";
    hash = "sha256-V92FpR2JuGPjCAK2BIMRbUab2c7J7AviMtPt4xMEtQA=";
  };

  nativeBuildInputs = [ cmake pkg-config ];
  buildInputs = [ soapysdr curl jsoncpp libusb1 ];

  # Module load, wire protocol and DC-removal tests; no hardware needed.
  doCheck = true;

  postInstall = ''
    install -Dm644 /dev/stdin $out/lib/udev/rules.d/70-espsdr.rules <<'EOF'
    SUBSYSTEM=="usb", ATTRS{idVendor}=="303a", ATTRS{idProduct}=="4531", MODE="0660", TAG+="uaccess"
    EOF
  '';

  meta = {
    description = "SoapySDR module for the ESP-SDR ESP32-S31 streaming firmware";
    homepage = "https://github.com/ESPARGOS/SoapyESPSDR";
    license = lib.licenses.gpl3Only;
    # The Ethernet transport binds to an interface with SO_BINDTODEVICE.
    platforms = lib.platforms.linux;
    mainProgram = "espsdr_loss_monitor";
  };
}
