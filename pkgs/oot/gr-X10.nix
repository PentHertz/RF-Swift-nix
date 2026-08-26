# X10 home-automation protocol decoder (OOT for GNU Radio 3.10).
{ lib , fetchFromGitHub , gnuradioPackages , cmake , pkg-config , boost , spdlog , gmp , log4cpp , volk , fftwFloat , python3Packages }:

gnuradioPackages.mkDerivation {
  pname = "gr-X10";
  version = "3.10";

  src = fetchFromGitHub {
    owner = "cpoore1";
    repo = "gr-X10";
    rev = "56ad834fbba18a3a11870586ca01e975074d6b8c";
    hash = "sha256-m44pEXcCN4dCHWB5peSRajl37cu524Gnq/mYmVdYfCk=";
  };

  nativeBuildInputs = [ cmake pkg-config python3Packages.pybind11 ];
  buildInputs = [ boost spdlog gmp log4cpp volk fftwFloat python3Packages.numpy ];
  cmakeFlags = [ "-DCMAKE_POLICY_VERSION_MINIMUM=3.5" ];
  env.NIX_CFLAGS_COMPILE = "-Wno-error -Wno-deprecated-declarations -Wno-narrowing -fpermissive";

  meta = {
    description = "X10 home-automation protocol decoder";
    homepage = "https://github.com/cpoore1/gr-X10";
    license = lib.licenses.gpl3Plus;
    platforms = lib.platforms.linux;
  };
}
