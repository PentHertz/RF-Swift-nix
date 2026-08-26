# Aaronia RTSA spectrum analyzer support (OOT for GNU Radio 3.10).
{ lib , fetchFromGitHub , gnuradioPackages , cmake , pkg-config , boost , spdlog , gmp , log4cpp , volk , fftwFloat , python3Packages , rapidjson, libspectranstream, curl }:

gnuradioPackages.mkDerivation {
  pname = "gr-aaronia_rtsa";
  version = "3.10";

  src = fetchFromGitHub {
    owner = "hb9fxq";
    repo = "gr-aaronia_rtsa";
    rev = "72b291b09c503fa38ce7a7805d1e4e7b860e73ba";
    hash = "sha256-Yu1vJOlShTmNT+u6cVQ2dNlZBO58G/XToHGVA51GnzA=";
  };

  nativeBuildInputs = [ cmake pkg-config python3Packages.pybind11 ];
  buildInputs = [ boost spdlog gmp log4cpp volk fftwFloat python3Packages.numpy rapidjson libspectranstream curl ];
  cmakeFlags = [ "-DCMAKE_POLICY_VERSION_MINIMUM=3.5" "-DRapidJSON_DIR=${rapidjson}/lib/cmake/RapidJSON" ];
  env.NIX_CFLAGS_COMPILE = "-Wno-error -Wno-deprecated-declarations -Wno-narrowing -fpermissive -I${libspectranstream}/include";

  meta = {
    description = "Aaronia RTSA spectrum analyzer support";
    homepage = "https://github.com/hb9fxq/gr-aaronia_rtsa";
    license = lib.licenses.gpl3Plus;
    platforms = lib.platforms.linux;
  };
}
