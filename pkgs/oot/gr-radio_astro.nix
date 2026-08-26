# radio astronomy signal processing (OOT for GNU Radio 3.10).
{ lib , fetchFromGitHub , gnuradioPackages , cmake , pkg-config , boost , spdlog , gmp , log4cpp , volk , fftwFloat , python3Packages , orc }:

gnuradioPackages.mkDerivation {
  pname = "gr-radio_astro";
  version = "3.10";

  src = fetchFromGitHub {
    owner = "WVURAIL";
    repo = "gr-radio_astro";
    rev = "5d23276e8dba8b10ef58e8c6dfe2bd1f628f31a1";
    hash = "sha256-LNDqoDkdk5qoVr2uAWc6mbm+ZSjNZkRpMjTF9rznME8=";
  };

  nativeBuildInputs = [ cmake pkg-config python3Packages.pybind11 ];
  buildInputs = [ boost spdlog gmp log4cpp volk fftwFloat python3Packages.numpy orc python3Packages.ephem ];
  cmakeFlags = [ "-DCMAKE_POLICY_VERSION_MINIMUM=3.5" ];
  env.NIX_CFLAGS_COMPILE = "-Wno-error -Wno-deprecated-declarations -Wno-narrowing -fpermissive";

  meta = {
    description = "radio astronomy signal processing";
    homepage = "https://github.com/WVURAIL/gr-radio_astro";
    license = lib.licenses.gpl3Plus;
    platforms = lib.platforms.linux;
  };
}
