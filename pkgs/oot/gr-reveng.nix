# CRC/checksum reverse engineering (OOT for GNU Radio 3.10).
{ lib , fetchFromGitHub , gnuradioPackages , cmake , pkg-config , boost , spdlog , gmp , log4cpp , volk , fftwFloat , python3Packages }:

gnuradioPackages.mkDerivation {
  pname = "gr-reveng";
  version = "3.10";

  src = fetchFromGitHub {
    owner = "paulgclark";
    repo = "gr-reveng";
    rev = "b36bfa2b67320f9094459a59476c79c81a4933d2";
    hash = "sha256-ws6Yt6U0+6EvTpT8i/uywaJK0mkzcesv+nMeH5awk+Q=";
  };

  nativeBuildInputs = [ cmake pkg-config python3Packages.pybind11 ];
  buildInputs = [ boost spdlog gmp log4cpp volk fftwFloat python3Packages.numpy ];
  cmakeFlags = [ "-DCMAKE_POLICY_VERSION_MINIMUM=3.5" ];
  env.NIX_CFLAGS_COMPILE = "-Wno-error -Wno-deprecated-declarations -Wno-narrowing -fpermissive";

  meta = {
    description = "CRC/checksum reverse engineering";
    homepage = "https://github.com/paulgclark/gr-reveng";
    license = lib.licenses.gpl3Plus;
    platforms = lib.platforms.linux;
  };
}
