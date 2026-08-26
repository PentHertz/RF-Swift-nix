# DCF77 time-signal receiver (OOT for GNU Radio 3.10).
{ lib , fetchFromGitHub , gnuradioPackages , cmake , pkg-config , boost , spdlog , gmp , log4cpp , volk , fftwFloat , python3Packages }:

gnuradioPackages.mkDerivation {
  pname = "gr-DCF77_Receiver";
  version = "3.10";

  src = fetchFromGitHub {
    owner = "henningM1r";
    repo = "gr_DCF77_Receiver";
    rev = "07924ae35a2bfe4e11fa25bb7e2e56dbaa3c1758";
    hash = "sha256-uxoTXlXGidXOr9CCtrLmxoJ/Ve+X/RN4I0EdoDDvF8c=";
  };

  nativeBuildInputs = [ cmake pkg-config python3Packages.pybind11 ];
  buildInputs = [ boost spdlog gmp log4cpp volk fftwFloat python3Packages.numpy ];
  cmakeFlags = [ "-DCMAKE_POLICY_VERSION_MINIMUM=3.5" ];
  env.NIX_CFLAGS_COMPILE = "-Wno-error -Wno-deprecated-declarations -Wno-narrowing -fpermissive";

  meta = {
    description = "DCF77 time-signal receiver";
    homepage = "https://github.com/henningM1r/gr_DCF77_Receiver";
    license = lib.licenses.gpl3Plus;
    platforms = lib.platforms.linux;
  };
}
