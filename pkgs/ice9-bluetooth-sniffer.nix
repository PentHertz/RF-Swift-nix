# ice9-bluetooth-sniffer: Bluetooth (BLE + Classic) sniffer for HackRF/BladeRF/USRP
# (mikeryan). CPU FFT path via FFTW (the optional Vulkan/glslang GPU path is off).
{ lib, stdenv, fetchFromGitHub, cmake, pkg-config, xxd
, liquid-dsp, fftwFloat, libpcap, hackrf, libbladeRF, uhd }:

stdenv.mkDerivation {
  pname = "ice9-bluetooth-sniffer";
  version = "1.4-unstable";

  src = fetchFromGitHub {
    owner = "mikeryan";
    repo = "ice9-bluetooth-sniffer";
    rev = "master";
    hash = "sha256-1MM05MB9TlyjLj/LG0xZ27EQPqCyzljpagZnUfiIkog=";
  };

  nativeBuildInputs = [ cmake pkg-config xxd ];
  buildInputs = [ liquid-dsp fftwFloat libpcap hackrf libbladeRF uhd ];
  # gcc-15 header strictness on the vendored C sources.
  env.NIX_CFLAGS_COMPILE = "-Wno-error";
  cmakeFlags = [ "-DCMAKE_POLICY_VERSION_MINIMUM=3.5" ];

  meta = {
    description = "Bluetooth Classic + BLE sniffer for HackRF / BladeRF / USRP";
    homepage = "https://github.com/mikeryan/ice9-bluetooth-sniffer";
    license = lib.licenses.gpl2Plus;
    platforms = lib.platforms.linux;
    mainProgram = "ice9-bluetooth";
  };
}
