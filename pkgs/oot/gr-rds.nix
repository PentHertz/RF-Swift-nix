# gr-rds: FM RDS/TMC decoder OOT for GNU Radio (bastibl), 3.10 branch.
{ lib, fetchFromGitHub, gnuradioPackages, cmake, pkg-config
, boost, spdlog, gmp, log4cpp, volk, fftwFloat, python3Packages }:

gnuradioPackages.mkDerivation {
  pname = "gr-rds";
  version = "3.10";

  src = fetchFromGitHub {
    owner = "bastibl";
    repo = "gr-rds";
    rev = "a4fae2787bc1115c04721d49bee39cfa2c3adcb2";
    hash = "sha256-0tLYZDSZ3rQmj+kEQBObcARoDfWxpGKJ5/VLEWkaE+Y=";
  };

  nativeBuildInputs = [ cmake pkg-config python3Packages.pybind11 ];
  buildInputs = [ boost spdlog gmp log4cpp volk fftwFloat python3Packages.numpy ];
  cmakeFlags = [ "-DCMAKE_POLICY_VERSION_MINIMUM=3.5" ];

  meta = {
    description = "RDS/TMC decoder blocks for GNU Radio";
    homepage = "https://github.com/bastibl/gr-rds";
    license = lib.licenses.gpl3Plus;
    platforms = lib.platforms.linux;
  };
}
