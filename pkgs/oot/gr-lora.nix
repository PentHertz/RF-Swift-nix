# LoRa PHY receiver (rpp0) (OOT for GNU Radio 3.10).
{ lib , fetchFromGitHub , gnuradioPackages , cmake , pkg-config , boost , spdlog , gmp , log4cpp , volk , fftwFloat , python3Packages , liquid-dsp }:

gnuradioPackages.mkDerivation {
  pname = "gr-lora";
  version = "3.10";

  src = fetchFromGitHub {
    owner = "rpp0";
    repo = "gr-lora";
    rev = "90343d45a3c73c84d32d74b8603b6c01de025b08";
    hash = "sha256-Lpe1RK9YPL+JEa8hA4eMx2CfT1eI05M5BimwgwSxgBI=";
  };

  nativeBuildInputs = [ cmake pkg-config python3Packages.pybind11 ];
  buildInputs = [ boost spdlog gmp log4cpp volk fftwFloat python3Packages.numpy liquid-dsp ];
  cmakeFlags = [ "-DCMAKE_POLICY_VERSION_MINIMUM=3.5" ];
  env.NIX_CFLAGS_COMPILE = "-Wno-error -Wno-deprecated-declarations -Wno-narrowing -fpermissive";

  meta = {
    description = "LoRa PHY receiver (rpp0)";
    homepage = "https://github.com/rpp0/gr-lora";
    license = lib.licenses.gpl3Plus;
    platforms = lib.platforms.linux;
  };
}
