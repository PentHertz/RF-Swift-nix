# alternative WiFi (802.11) implementation (OOT for GNU Radio 3.10).
{ lib , fetchFromGitHub , gnuradioPackages , cmake , pkg-config , boost , spdlog , gmp , log4cpp , volk , fftwFloat , python3Packages, uhd }:

gnuradioPackages.mkDerivation {
  pname = "gr-ieee80211";
  version = "3.10";

  src = fetchFromGitHub {
    owner = "cloud9477";
    repo = "gr-ieee80211";
    rev = "add75653e8de63361b9d3d34606eb8dc5b6029c5";
    hash = "sha256-xAkKqx+vD66Vryw2DyUgBcz8xxR216SoH972qLrPTW4=";
  };

  nativeBuildInputs = [ cmake pkg-config python3Packages.pybind11 ];
  buildInputs = [ boost spdlog gmp log4cpp volk fftwFloat python3Packages.numpy uhd ];
  cmakeFlags = [ "-DCMAKE_POLICY_VERSION_MINIMUM=3.5" ];
  env.NIX_CFLAGS_COMPILE = "-Wno-error -Wno-deprecated-declarations -Wno-narrowing -fpermissive";

  meta = {
    description = "alternative WiFi (802.11) implementation";
    homepage = "https://github.com/cloud9477/gr-ieee80211";
    license = lib.licenses.gpl3Plus;
    platforms = lib.platforms.linux;
  };
}
