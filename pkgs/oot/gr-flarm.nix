# FLARM collision-avoidance decoder (OOT for GNU Radio 3.10).
{ lib , fetchFromGitHub , gnuradioPackages , cmake , pkg-config , boost , spdlog , gmp , log4cpp , volk , fftwFloat , python3Packages, turbofec }:

gnuradioPackages.mkDerivation {
  pname = "gr-flarm";
  version = "3.10";

  src = fetchFromGitHub {
    owner = "argilo";
    repo = "gr-flarm";
    rev = "0958daef705826c43cc59b01e1d3fd528f974d55";
    hash = "sha256-m8ykN5mOoaYZxxpdGQbLHy7iwQvsyYD4lymngLbZW1M=";
  };

  nativeBuildInputs = [ cmake pkg-config python3Packages.pybind11 ];
  buildInputs = [ boost spdlog gmp log4cpp volk fftwFloat python3Packages.numpy turbofec ];
  cmakeFlags = [ "-DCMAKE_POLICY_VERSION_MINIMUM=3.5" ];
  env.NIX_CFLAGS_COMPILE = "-Wno-error -Wno-deprecated-declarations -Wno-narrowing -fpermissive";

  meta = {
    description = "FLARM collision-avoidance decoder";
    homepage = "https://github.com/argilo/gr-flarm";
    license = lib.licenses.gpl3Plus;
    platforms = lib.platforms.linux;
  };
}
