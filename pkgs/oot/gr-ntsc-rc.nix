# NTSC video signal processing (OOT for GNU Radio 3.10).
{ lib , fetchFromGitHub , gnuradioPackages , cmake , pkg-config , boost , spdlog , gmp , log4cpp , volk , fftwFloat , python3Packages }:

gnuradioPackages.mkDerivation {
  pname = "gr-ntsc-rc";
  version = "3.10";

  src = fetchFromGitHub {
    owner = "FlUxIuS";
    repo = "gr-ntsc-rc";
    rev = "b8c54ea2f66f0e6eb604a1a749d0e653f0b0cfca";
    hash = "sha256-ibVueZ+RcY9Gnm/WzMy7gR8WhlSbA1w9CTIo60I+S2w=";
  };

  nativeBuildInputs = [ cmake pkg-config python3Packages.pybind11 ];
  buildInputs = [ boost spdlog gmp log4cpp volk fftwFloat python3Packages.numpy ];
  cmakeFlags = [ "-DCMAKE_POLICY_VERSION_MINIMUM=3.5" ];
  env.NIX_CFLAGS_COMPILE = "-Wno-error -Wno-deprecated-declarations -Wno-narrowing -fpermissive";

  meta = {
    description = "NTSC video signal processing";
    homepage = "https://github.com/FlUxIuS/gr-ntsc-rc";
    license = lib.licenses.gpl3Plus;
    platforms = lib.platforms.linux;
  };
}
