# Unmanned Aerial System datalink decoder (OOT for GNU Radio 3.10).
{ lib , fetchFromGitHub , gnuradioPackages , cmake , pkg-config , boost , spdlog , gmp , log4cpp , volk , fftwFloat , python3Packages }:

gnuradioPackages.mkDerivation {
  pname = "gr-uaslink";
  version = "3.10";

  src = fetchFromGitHub {
    owner = "FlUxIuS";
    repo = "gr-uaslink";
    rev = "176bcf651ef32e221f0c38f03af209a8d2ad9875";
    hash = "sha256-BjXnfOpWtGpXA+8Ln6inMP/J9LWW/tYxsNdFQ0t+ASU=";
  };

  nativeBuildInputs = [ cmake pkg-config python3Packages.pybind11 ];
  buildInputs = [ boost spdlog gmp log4cpp volk fftwFloat python3Packages.numpy ];
  cmakeFlags = [ "-DCMAKE_POLICY_VERSION_MINIMUM=3.5" ];
  env.NIX_CFLAGS_COMPILE = "-Wno-error -Wno-deprecated-declarations -Wno-narrowing -fpermissive";

  meta = {
    description = "Unmanned Aerial System datalink decoder";
    homepage = "https://github.com/FlUxIuS/gr-uaslink";
    license = lib.licenses.gpl3Plus;
    platforms = lib.platforms.linux;
  };
}
