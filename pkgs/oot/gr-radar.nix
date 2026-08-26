# radar signal processing toolkit (OOT for GNU Radio 3.10).
{ lib , fetchFromGitHub , gnuradioPackages , cmake , pkg-config , boost , spdlog , gmp , log4cpp , volk , fftwFloat , python3Packages, git, libsForQt5, uhd }:

gnuradioPackages.mkDerivation {
  pname = "gr-radar";
  version = "3.10";

  src = fetchFromGitHub {
    owner = "radioconda";
    repo = "gr-radar";
    rev = "c59350d3c67c0bc563368206c9e39db7713ac8d6";
    hash = "sha256-rYSRymDIfQAcPwL8CBlFxMc1DBqC2DDx/A007MqCzYc=";
  };

  nativeBuildInputs = [ cmake pkg-config git python3Packages.pybind11 libsForQt5.wrapQtAppsHook ];
  dontWrapQtApps = true;
  buildInputs = [ boost spdlog gmp log4cpp volk fftwFloat python3Packages.numpy libsForQt5.qtbase libsForQt5.qwt uhd fftwFloat python3Packages.pyqt5 ];
  cmakeFlags = [ "-DCMAKE_POLICY_VERSION_MINIMUM=3.5" ];
  env.NIX_CFLAGS_COMPILE = "-Wno-error -Wno-deprecated-declarations -Wno-narrowing -fpermissive";

  meta = {
    description = "radar signal processing toolkit";
    homepage = "https://github.com/radioconda/gr-radar";
    license = lib.licenses.gpl3Plus;
    platforms = lib.platforms.linux;
  };
}
