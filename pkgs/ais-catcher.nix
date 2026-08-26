# AIS-catcher: multi-device AIS receiver/decoder. Not in nixpkgs, built from source.
{ lib, stdenv, fetchFromGitHub, cmake, pkg-config, rtl-sdr-osmocom, libusb1
, soapysdr-with-plugins, curl, zlib, airspy, airspyhf, hackrf }:

stdenv.mkDerivation rec {
  pname = "ais-catcher";
  version = "0.60";

  src = fetchFromGitHub {
    owner = "jvde-github";
    repo = "AIS-catcher";
    rev = "v${version}";
    hash = "sha256-Y+0DTpcwViaTOXgPk6PnoJESOPNaeoiG9m7sYGfpcSY=";
  };

  nativeBuildInputs = [ cmake pkg-config ];
  buildInputs = [ rtl-sdr-osmocom libusb1 soapysdr-with-plugins curl zlib airspy airspyhf hackrf ];

  # Older cmake_minimum_required; CMake 4 needs this to stay compatible.
  cmakeFlags = [ "-DCMAKE_POLICY_VERSION_MINIMUM=3.5" ];

  meta = {
    description = "AIS receiver/decoder for RTL-SDR, Airspy, HackRF and SoapySDR devices";
    homepage = "https://github.com/jvde-github/AIS-catcher";
    license = lib.licenses.mit;
    platforms = lib.platforms.linux;
    mainProgram = "AIS-catcher";
  };
}
