# Digital Speech Decoder (P25/DMR/NXDN) (OOT for GNU Radio 3.10).
{ lib , fetchFromGitHub , gnuradioPackages , cmake , pkg-config , boost , spdlog , gmp , log4cpp , volk , fftwFloat , python3Packages, libsndfile, itpp }:

gnuradioPackages.mkDerivation {
  pname = "gr-dsd";
  version = "3.10";

  src = fetchFromGitHub {
    owner = "argilo";
    repo = "gr-dsd";
    rev = "183989c84fbf303f9a63492a1dc5a8c05d316f3e";
    hash = "sha256-0ObbCOUp1dVLU9bD4PSbdoQqlXo6V855fKjx3LtA1lM=";
  };

  nativeBuildInputs = [ cmake pkg-config python3Packages.pybind11 ];
  buildInputs = [ boost spdlog gmp log4cpp volk fftwFloat python3Packages.numpy itpp ];
  cmakeFlags = [
    "-DCMAKE_POLICY_VERSION_MINIMUM=3.5"
    "-DLIBSNDFILE_INCLUDE_DIR=${libsndfile.dev}/include"
    "-DLIBSNDFILE_LIBRARY=${libsndfile.out}/lib/libsndfile.so"
  ];
  env.NIX_CFLAGS_COMPILE = "-Wno-error -Wno-deprecated-declarations -Wno-narrowing -fpermissive -I${libsndfile.dev}/include";

  meta = {
    description = "Digital Speech Decoder (P25/DMR/NXDN)";
    homepage = "https://github.com/argilo/gr-dsd";
    license = lib.licenses.gpl3Plus;
    platforms = lib.platforms.linux;
  };
}
