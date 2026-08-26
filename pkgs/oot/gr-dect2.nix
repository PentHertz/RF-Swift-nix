# DECT cordless phone receiver/decoder.
{ lib, fetchFromGitHub, gnuradioPackages, cmake, pkg-config
, boost, spdlog, gmp, log4cpp, volk, fftwFloat, python3Packages }:

gnuradioPackages.mkDerivation {
  pname = "gr-dect2";
  version = "maint-3.10";

  src = fetchFromGitHub {
    owner = "pavelyazev";
    repo = "gr-dect2";
    rev = "0d973fe433eebfe3eee6e7f2eeb1322f8976ab42";
    hash = "sha256-zb22toxkVeAeMm3PHRS8crZ1PejjkAhvCFgz30kiPzo=";
  };

  nativeBuildInputs = [ cmake pkg-config python3Packages.pybind11 ];
  buildInputs = [ boost spdlog gmp log4cpp volk fftwFloat python3Packages.numpy ];
  cmakeFlags = [ "-DCMAKE_POLICY_VERSION_MINIMUM=3.5" ];

  meta = {
    description = "DECT cordless phone receiver/decoder";
    homepage = "https://github.com/pavelyazev/gr-dect2";
    license = lib.licenses.gpl3Plus;
    platforms = lib.platforms.linux;
  };
}
