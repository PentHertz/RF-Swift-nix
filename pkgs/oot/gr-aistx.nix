# AIS transmitter blocks (OOT for GNU Radio 3.10).
{ lib , fetchFromGitHub , gnuradioPackages , cmake , pkg-config , boost , spdlog , gmp , log4cpp , volk , fftwFloat , python3Packages }:

gnuradioPackages.mkDerivation {
  pname = "gr-aistx";
  version = "3.10";

  src = fetchFromGitHub {
    owner = "bkerler";
    repo = "ais";
    rev = "170d8630b8bf7e538b013f975619d7e96f682b92";
    hash = "sha256-z+BQfUKIakJMFG7vG1TdS831tK39UwPgfefX6W8hCWM=";
  };
  sourceRoot = "source/gr-aistx";

  nativeBuildInputs = [ cmake pkg-config python3Packages.pybind11 ];
  buildInputs = [ boost spdlog gmp log4cpp volk fftwFloat python3Packages.numpy ];
  cmakeFlags = [ "-DCMAKE_POLICY_VERSION_MINIMUM=3.5" ];
  env.NIX_CFLAGS_COMPILE = "-Wno-error -Wno-deprecated-declarations -Wno-narrowing -fpermissive";

  meta = {
    description = "AIS transmitter blocks";
    homepage = "https://github.com/bkerler/ais";
    license = lib.licenses.gpl3Plus;
    platforms = lib.platforms.linux;
  };
}
