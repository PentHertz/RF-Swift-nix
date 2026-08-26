# Sandia signal-processing blocks (OOT for GNU Radio 3.10).
{ lib , fetchFromGitHub , gnuradioPackages , cmake , pkg-config , boost , spdlog , gmp , log4cpp , volk , fftwFloat , python3Packages, gr-pdu_utils }:

gnuradioPackages.mkDerivation {
  pname = "gr-sandia_utils";
  version = "3.10";

  src = fetchFromGitHub {
    owner = "PentHertz";
    repo = "gr-sandia_utils_resolute";
    rev = "c03360a6b1c5c9928461343c53d503192b679d04";
    hash = "sha256-7zfUGuXR8XCAQPIccLEKkdZ7tgomPzM7C6LYEmk4brc=";
  };

  nativeBuildInputs = [ cmake pkg-config python3Packages.pybind11 ];
  buildInputs = [ boost spdlog gmp log4cpp volk fftwFloat python3Packages.numpy gr-pdu_utils ];
  cmakeFlags = [ "-DCMAKE_POLICY_VERSION_MINIMUM=3.5" ];
  env.NIX_CFLAGS_COMPILE = "-Wno-error -Wno-deprecated-declarations -Wno-narrowing -fpermissive";

  meta = {
    description = "Sandia signal-processing blocks";
    homepage = "https://github.com/PentHertz/gr-sandia_utils_resolute";
    license = lib.licenses.gpl3Plus;
    platforms = lib.platforms.linux;
  };
}
