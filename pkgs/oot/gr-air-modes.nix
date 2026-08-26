# Mode-S / ADS-B receiver (bkerler 3.10 fork).
{ lib, fetchFromGitHub, gnuradioPackages, cmake, pkg-config
, boost, spdlog, gmp, log4cpp, volk, fftwFloat, python3Packages }:

gnuradioPackages.mkDerivation {
  pname = "gr-air-modes";
  version = "maint-3.10";

  src = fetchFromGitHub {
    owner = "bkerler";
    repo = "gr-air-modes";
    rev = "3a946c55f74da8395158b43fc69aab3902432aca";
    hash = "sha256-HuQvK2anVcU7+JxZvOKNJhMwj8C8lYDbauMKX/Aus1E=";
  };

  nativeBuildInputs = [ cmake pkg-config python3Packages.pybind11 ];
  buildInputs = [ boost spdlog gmp log4cpp volk fftwFloat python3Packages.numpy ];
  cmakeFlags = [ "-DCMAKE_POLICY_VERSION_MINIMUM=3.5" ];

  meta = {
    description = "Mode-S / ADS-B receiver (bkerler 3.10 fork)";
    homepage = "https://github.com/bkerler/gr-air-modes";
    license = lib.licenses.gpl3Plus;
    platforms = lib.platforms.linux;
  };
}
