# esp-sdr-bridge (z2labs): SpyServer (5555) and rtl_tcp (1234) server for the
# ESP-SDR ESP32-S3 continuous I/Q stream, so SDR++, SDR# or GNU Radio can use
# it. Matches RF-Swift-images' espsdr_sdrhacks_install (pipx, v0.1.0); the
# matching ESP32-S3 firmware ships in share/esp-sdr-bridge.
{ lib, python3Packages, fetchFromGitHub, fetchurl }:

let
  version = "0.1.0";
  firmware = fetchurl {
    url = "https://github.com/z2labs/esp-sdr-bridge/releases/download/v${version}/esp-sdr-s3-iq-stream.bin";
    hash = "sha256-nWKL3NNP6eCr/iuxDieAYSMEfBbj8Qg8V/g7b/hmHn4=";
  };
in
python3Packages.buildPythonApplication {
  pname = "esp-sdr-bridge";
  inherit version;
  pyproject = true;

  src = fetchFromGitHub {
    owner = "z2labs";
    repo = "esp-sdr-bridge";
    rev = "v${version}";
    hash = "sha256-8AvvuhzBVb6S/rHA1F4wEQH/hylOuMPLOq4S8d9lDDQ=";
  };

  build-system = [ python3Packages.setuptools ];
  dependencies = with python3Packages; [ numpy pyserial ];

  pythonImportsCheck = [ "esp_sdr_bridge" ];

  postInstall = ''
    install -Dm644 ${firmware} $out/share/esp-sdr-bridge/esp-sdr-s3-iq-stream-v${version}.bin
  '';

  meta = {
    description = "SpyServer and rtl_tcp bridge for the ESP-SDR ESP32-S3 I/Q stream";
    homepage = "https://github.com/z2labs/esp-sdr-bridge";
    license = lib.licenses.gpl3Only;
    mainProgram = "esp-sdr-bridge";
  };
}
