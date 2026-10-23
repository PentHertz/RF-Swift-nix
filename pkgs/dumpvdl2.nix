# dumpvdl2: VDL Mode 2 decoder for aircraft ACARS/CPDLC over VHF.
{ lib, stdenv, fetchFromGitHub, cmake, pkg-config, libacars, glib
, rtl-sdr-osmocom, soapysdr-with-plugins, zlib, sqlite }:

stdenv.mkDerivation rec {
  pname = "dumpvdl2";
  version = "2.7.0";

  src = fetchFromGitHub {
    owner = "szpajder";
    repo = "dumpvdl2";
    rev = "v${version}";
    hash = "sha256-sKbJdSUmtwFdn1f6GR24L5fmUA351icLm6rsfK81+Gw=";
  };

  nativeBuildInputs = [ cmake pkg-config ];
  buildInputs = [ libacars glib rtl-sdr-osmocom soapysdr-with-plugins zlib sqlite ];

  # Older cmake_minimum_required; CMake 4 needs this to stay compatible.
  cmakeFlags = [ "-DCMAKE_POLICY_VERSION_MINIMUM=3.5" ];

  meta = {
    description = "VDL Mode 2 message decoder and protocol analyzer";
    homepage = "https://github.com/szpajder/dumpvdl2";
    license = lib.licenses.gpl3Plus;
    platforms = lib.platforms.linux;
    mainProgram = "dumpvdl2";
  };
}
