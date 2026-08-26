# FHSS utilities (Sandia) (OOT for GNU Radio 3.10).
{ lib , fetchFromGitHub , gnuradioPackages , cmake , pkg-config , boost , spdlog , gmp , log4cpp , volk , fftwFloat , python3Packages, gr-pdu_utils, gr-timing_utils }:

gnuradioPackages.mkDerivation {
  pname = "gr-fhss_utils";
  version = "3.10";

  src = fetchFromGitHub {
    owner = "PentHertz";
    repo = "gr-fhss_utils_resolute";
    rev = "af1345f17298f52d07f500d79f935dcb24dcc39b";
    hash = "sha256-1ukEcDLAVu7NrJsa66AgHdI+3FArKzfwzyf5NCn1hsM=";
  };

  nativeBuildInputs = [ cmake pkg-config python3Packages.pybind11 ];
  buildInputs = [ boost spdlog gmp log4cpp volk fftwFloat python3Packages.numpy gr-pdu_utils gr-timing_utils ];
  cmakeFlags = [ "-DCMAKE_POLICY_VERSION_MINIMUM=3.5" ];
  env.NIX_CFLAGS_COMPILE = "-Wno-error -Wno-deprecated-declarations -Wno-narrowing -fpermissive";

  meta = {
    description = "FHSS utilities (Sandia)";
    homepage = "https://github.com/PentHertz/gr-fhss_utils_resolute";
    license = lib.licenses.gpl3Plus;
    platforms = lib.platforms.linux;
  };
}
