# ADS-B (Mode-S) aircraft transponder decoder.
{ lib, fetchFromGitHub, gnuradioPackages, cmake, pkg-config
, boost, spdlog, gmp, log4cpp, volk, fftwFloat, python3Packages }:

gnuradioPackages.mkDerivation {
  pname = "gr-adsb";
  version = "maint-3.10";

  src = fetchFromGitHub {
    owner = "mhostetter";
    repo = "gr-adsb";
    rev = "b1b5b139c8849d0090319ba12140bdc88fce236f";
    hash = "sha256-8oisTT2Be+H9jFuo8DuakeszFhFfsa02LZ0grC5yToI=";
  };

  nativeBuildInputs = [ cmake pkg-config python3Packages.pybind11 ];
  buildInputs = [ boost spdlog gmp log4cpp volk fftwFloat python3Packages.numpy ];
  cmakeFlags = [ "-DCMAKE_POLICY_VERSION_MINIMUM=3.5" ];

  meta = {
    description = "ADS-B (Mode-S) aircraft transponder decoder";
    homepage = "https://github.com/mhostetter/gr-adsb";
    license = lib.licenses.gpl3Plus;
    platforms = lib.platforms.linux;
  };
}
