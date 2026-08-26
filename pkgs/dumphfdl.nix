# dumphfdl: HFDL (High Frequency Data Link) decoder.
{ lib, stdenv, fetchFromGitHub, cmake, pkg-config, libacars, glib, libsysprof-capture, pcre2, libconfig
, soapysdr-with-plugins, fftwFloat, liquid-dsp, zlib, sqlite }:

stdenv.mkDerivation rec {
  pname = "dumphfdl";
  version = "1.4.1";

  src = fetchFromGitHub {
    owner = "szpajder";
    repo = "dumphfdl";
    rev = "v${version}";
    hash = "sha256-IMl/O7MMr8U/plsjqRPze15+dCLGPkEZx93reXOe5q8=";
  };

  nativeBuildInputs = [ cmake pkg-config ];
  # glib's .pc privately requires sysprof-capture-4; provide it so pkg-config
  # resolves glib-2.0 in this build (it uses glib's private requires).
  buildInputs = [ libacars glib libsysprof-capture pcre2 libconfig soapysdr-with-plugins fftwFloat liquid-dsp zlib sqlite ];

  cmakeFlags = [
    # Older cmake_minimum_required; CMake 4 needs this to stay compatible.
    "-DCMAKE_POLICY_VERSION_MINIMUM=3.5"
    # dumphfdl checks the liquid-dsp version with check_c_source_runs, which
    # cannot load libliquid.so at test time inside the Nix sandbox and so
    # wrongly reports it "too old". liquid-dsp here is 1.8.x, so pre-seed the
    # cache result to skip the run.
    "-DLIQUIDDSP_VERSION_CHECK=1"
    "-DLIQUIDDSP_VERSION_CHECK_EXITCODE=0"
  ];

  meta = {
    description = "HFDL (High Frequency Data Link) decoder";
    homepage = "https://github.com/szpajder/dumphfdl";
    license = lib.licenses.gpl3Plus;
    platforms = lib.platforms.linux;
    mainProgram = "dumphfdl";
  };
}
