# additional GUI widgets and displays (OOT for GNU Radio 3.10).
{ lib , fetchFromGitHub , gnuradioPackages , cmake , pkg-config , boost , spdlog , gmp , log4cpp , volk , fftwFloat , python3Packages , libsForQt5 }:

gnuradioPackages.mkDerivation {
  pname = "gr-guiextra";
  version = "3.10";

  src = fetchFromGitHub {
    owner = "ghostop14";
    repo = "gr-guiextra";
    rev = "ce6874899314d64228e0524df712c3c35e53dcfe";
    hash = "sha256-K2NuuAZjXe3I+HqMIl/G/Gd8/9ZS59Pd3udVRujxkJA=";
  };

  nativeBuildInputs = [ cmake pkg-config python3Packages.pybind11 libsForQt5.wrapQtAppsHook ];
  dontWrapQtApps = true;
  buildInputs = [ boost spdlog gmp log4cpp volk fftwFloat python3Packages.numpy libsForQt5.qtbase ];
  cmakeFlags = [ "-DCMAKE_POLICY_VERSION_MINIMUM=3.5" ];
  env.NIX_CFLAGS_COMPILE = "-Wno-error -Wno-deprecated-declarations -Wno-narrowing -fpermissive";

  meta = {
    description = "additional GUI widgets and displays";
    homepage = "https://github.com/ghostop14/gr-guiextra";
    license = lib.licenses.gpl3Plus;
    platforms = lib.platforms.linux;
  };
}
