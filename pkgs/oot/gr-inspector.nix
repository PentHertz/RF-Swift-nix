# signal analysis and classification toolkit (OOT for GNU Radio 3.10).
{ lib , fetchFromGitHub , gnuradioPackages , cmake , pkg-config , boost , spdlog , gmp , log4cpp , volk , fftwFloat , python3Packages , libsForQt5 }:

gnuradioPackages.mkDerivation {
  pname = "gr-inspector";
  version = "3.10";

  src = fetchFromGitHub {
    owner = "gnuradio";
    repo = "gr-inspector";
    rev = "ad6a69e84eb847f30fe79ba657ba95ddcb211c0c";
    hash = "sha256-dE9lNSjCgSu+ZtfWGv9qZHFb7vG+XBi6jNMdw23VVcc=";
  };

  nativeBuildInputs = [ cmake pkg-config python3Packages.pybind11 libsForQt5.wrapQtAppsHook ];
  dontWrapQtApps = true;
  buildInputs = [ boost spdlog gmp log4cpp volk fftwFloat python3Packages.numpy libsForQt5.qwt libsForQt5.qtbase ];
  cmakeFlags = [ "-DCMAKE_POLICY_VERSION_MINIMUM=3.5" ];
  env.NIX_CFLAGS_COMPILE = "-Wno-error -Wno-deprecated-declarations -Wno-narrowing -fpermissive";

  meta = {
    description = "signal analysis and classification toolkit";
    homepage = "https://github.com/gnuradio/gr-inspector";
    license = lib.licenses.gpl3Plus;
    platforms = lib.platforms.linux;
  };
}
