# timing/synchronization utilities (Sandia) (OOT for GNU Radio 3.10).
{ lib , fetchFromGitHub , gnuradioPackages , cmake , pkg-config , boost , spdlog , gmp , log4cpp , volk , fftwFloat , python3Packages, git, gr-pdu_utils, gr-sandia_utils }:

gnuradioPackages.mkDerivation {
  pname = "gr-timing_utils";
  version = "3.10";

  src = fetchFromGitHub {
    owner = "PentHertz";
    repo = "gr-timing_utils_resolute";
    rev = "6bec46d401b0b5133c4d84bed3e5ed15bb514c36";
    hash = "sha256-RbGx4XOsrdHHBI+GZ86oR1/IK0GrmuYZ/N+cTFd2UFo=";
  };

  nativeBuildInputs = [ cmake pkg-config git python3Packages.pybind11 ];
  buildInputs = [ boost spdlog gmp log4cpp volk fftwFloat python3Packages.numpy gr-pdu_utils gr-sandia_utils ];
  cmakeFlags = [ "-DCMAKE_POLICY_VERSION_MINIMUM=3.5" ];
  env.NIX_CFLAGS_COMPILE = "-Wno-error -Wno-deprecated-declarations -Wno-narrowing -fpermissive";

  meta = {
    description = "timing/synchronization utilities (Sandia)";
    homepage = "https://github.com/PentHertz/gr-timing_utils_resolute";
    license = lib.licenses.gpl3Plus;
    platforms = lib.platforms.linux;
  };
}
