# 802.11 a/g/p WiFi PHY receiver/transmitter (bastibl). Runtime-depends on gr-foo (the example flowgraphs use foo blocks).
{ lib, fetchFromGitHub, gnuradioPackages, cmake, pkg-config
, boost, spdlog, gmp, log4cpp, volk, fftwFloat, python3Packages, gr-foo }:

gnuradioPackages.mkDerivation {
  pname = "gr-ieee802-11";
  version = "maint-3.10";

  src = fetchFromGitHub {
    owner = "bastibl";
    repo = "gr-ieee802-11";
    rev = "ad0598e4a874f4b8e1f391a1e0323e80df2b34ff";
    hash = "sha256-TAKcPzHWBEEFpHIBvC4I4U4WjDsIkzGkIzjiOrQ2OJE=";
  };

  nativeBuildInputs = [ cmake pkg-config python3Packages.pybind11 ];
  buildInputs = [ boost spdlog gmp log4cpp volk fftwFloat python3Packages.numpy gr-foo ];
  cmakeFlags = [ "-DCMAKE_POLICY_VERSION_MINIMUM=3.5" ];

  meta = {
    description = "802.11 a/g/p WiFi PHY receiver/transmitter";
    homepage = "https://github.com/bastibl/gr-ieee802-11";
    license = lib.licenses.gpl3Plus;
    platforms = lib.platforms.linux;
  };
}
