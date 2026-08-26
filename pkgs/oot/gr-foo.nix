# Utility blocks for GNU Radio (dependency of the gr-ieee802 modules).
{ lib, fetchFromGitHub, gnuradioPackages, cmake, pkg-config
, boost, spdlog, gmp, log4cpp, volk, fftwFloat, python3Packages }:

gnuradioPackages.mkDerivation {
  pname = "gr-foo";
  version = "maint-3.10";

  src = fetchFromGitHub {
    owner = "bastibl";
    repo = "gr-foo";
    rev = "4c2a471b0453b9dca669b2d9dfcbfba6278741d7";
    hash = "sha256-TlyuwbfM2txQCwcwdrOk5+qpTMF2m4YbRLvdZWQ/bOI=";
  };

  nativeBuildInputs = [ cmake pkg-config python3Packages.pybind11 ];
  buildInputs = [ boost spdlog gmp log4cpp volk fftwFloat python3Packages.numpy ];
  cmakeFlags = [ "-DCMAKE_POLICY_VERSION_MINIMUM=3.5" ];

  meta = {
    description = "Utility blocks for GNU Radio (dependency of the gr-ieee802 modules)";
    homepage = "https://github.com/bastibl/gr-foo";
    license = lib.licenses.gpl3Plus;
    platforms = lib.platforms.linux;
  };
}
