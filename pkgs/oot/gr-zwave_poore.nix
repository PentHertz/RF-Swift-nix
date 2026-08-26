# Z-Wave home-automation decoder (OOT for GNU Radio 3.10).
{ lib , fetchFromGitHub , gnuradioPackages , cmake , pkg-config , boost , spdlog , gmp , log4cpp , volk , fftwFloat , python3Packages }:

gnuradioPackages.mkDerivation {
  pname = "gr-zwave_poore";
  version = "3.10";

  src = fetchFromGitHub {
    owner = "cpoore1";
    repo = "gr-zwave_poore";
    rev = "59be8b1c19631c8c4e00f976fe4e9b356c1e71e5";
    hash = "sha256-sdKnyrUr59Gs/EK4q7U1BodMURWDrVuZlGHBstEaLro=";
  };

  nativeBuildInputs = [ cmake pkg-config python3Packages.pybind11 ];
  buildInputs = [ boost spdlog gmp log4cpp volk fftwFloat python3Packages.numpy ];
  cmakeFlags = [ "-DCMAKE_POLICY_VERSION_MINIMUM=3.5" ];
  env.NIX_CFLAGS_COMPILE = "-Wno-error -Wno-deprecated-declarations -Wno-narrowing -fpermissive";

  meta = {
    description = "Z-Wave home-automation decoder";
    homepage = "https://github.com/cpoore1/gr-zwave_poore";
    license = lib.licenses.gpl3Plus;
    platforms = lib.platforms.linux;
  };
}
