# Angle-of-Arrival estimation (OOT for GNU Radio 3.10).
{ lib , fetchFromGitHub , gnuradioPackages , cmake , pkg-config , boost , spdlog , gmp , log4cpp , volk , fftwFloat , python3Packages , eigen }:

gnuradioPackages.mkDerivation {
  pname = "gr-aoa";
  version = "3.10";

  src = fetchFromGitHub {
    owner = "MarcinWachowiak";
    repo = "gr-aoa";
    rev = "2e204865a10d89e57d2d76a09989ebff4da6f2ed";
    hash = "sha256-Qg2oNgIGeSh+DyCXFHmSN8pr6sRJh9sVB6hVwy+aRYg=";
  };

  nativeBuildInputs = [ cmake pkg-config python3Packages.pybind11 ];
  buildInputs = [ boost spdlog gmp log4cpp volk fftwFloat python3Packages.numpy eigen ];
  cmakeFlags = [ "-DCMAKE_POLICY_VERSION_MINIMUM=3.5" ];
  env.NIX_CFLAGS_COMPILE = "-Wno-error -Wno-deprecated-declarations -Wno-narrowing -fpermissive";

  meta = {
    description = "Angle-of-Arrival estimation";
    homepage = "https://github.com/MarcinWachowiak/gr-aoa";
    license = lib.licenses.gpl3Plus;
    platforms = lib.platforms.linux;
  };
}
