# 802.15.4 / ZigBee O-QPSK & CSS PHY (bastibl). Runtime-depends on gr-foo (the example flowgraphs use foo blocks).
{ lib, fetchFromGitHub, gnuradioPackages, cmake, pkg-config
, boost, spdlog, gmp, log4cpp, volk, fftwFloat, python3Packages, gr-foo }:

gnuradioPackages.mkDerivation {
  pname = "gr-ieee802-15-4";
  version = "maint-3.10";

  src = fetchFromGitHub {
    owner = "bastibl";
    repo = "gr-ieee802-15-4";
    rev = "a210b11fed2d307ef797ea79842b54f4e8ed3dd5";
    hash = "sha256-m/CukP6Wf+POr3LJXh4uIWfWb3l9tnMI6tufq2a//J8=";
  };

  nativeBuildInputs = [ cmake pkg-config python3Packages.pybind11 ];
  buildInputs = [ boost spdlog gmp log4cpp volk fftwFloat python3Packages.numpy gr-foo ];
  cmakeFlags = [ "-DCMAKE_POLICY_VERSION_MINIMUM=3.5" ];

  meta = {
    description = "802.15.4 / ZigBee O-QPSK & CSS PHY";
    homepage = "https://github.com/bastibl/gr-ieee802-15-4";
    license = lib.licenses.gpl3Plus;
    platforms = lib.platforms.linux;
  };
}
