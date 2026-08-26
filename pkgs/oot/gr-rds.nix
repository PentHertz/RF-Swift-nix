# gr-rds: FM RDS/TMC decoder OOT for GNU Radio (bastibl), 3.10 branch.
{ lib, fetchFromGitHub, gnuradioPackages, cmake, pkg-config
, boost, spdlog, gmp, log4cpp, volk, fftwFloat, python3Packages }:

gnuradioPackages.mkDerivation {
  pname = "gr-rds";
  version = "3.10";

  src = fetchFromGitHub {
    owner = "bastibl";
    repo = "gr-rds";
    rev = "maint-3.10";
    hash = "sha256-2MDSSrmihurC2//PQQM3PgoSQOK+D2blmu3FJ6cZtxE=";
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
