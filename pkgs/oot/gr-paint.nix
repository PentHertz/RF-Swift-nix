# Spectrum painter (draw images into the RF waterfall).
{ lib, fetchFromGitHub, gnuradioPackages, cmake, pkg-config
, boost, spdlog, gmp, log4cpp, volk, fftwFloat, python3Packages }:

gnuradioPackages.mkDerivation {
  pname = "gr-paint";
  version = "maint-3.10";

  src = fetchFromGitHub {
    owner = "drmpeg";
    repo = "gr-paint";
    rev = "c443e36e8ab22ea7819db28df7b69378027dd5b5";
    hash = "sha256-Pt6EFSRPYLeTGVhM96K+mq/jD9Ihs/mVtvulwdPD07U=";
  };

  nativeBuildInputs = [ cmake pkg-config python3Packages.pybind11 ];
  buildInputs = [ boost spdlog gmp log4cpp volk fftwFloat python3Packages.numpy ];
  cmakeFlags = [ "-DCMAKE_POLICY_VERSION_MINIMUM=3.5" ];

  meta = {
    description = "Spectrum painter (draw images into the RF waterfall)";
    homepage = "https://github.com/drmpeg/gr-paint";
    license = lib.licenses.gpl3Plus;
    platforms = lib.platforms.linux;
  };
}
