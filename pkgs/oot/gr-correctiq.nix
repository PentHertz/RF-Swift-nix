# IQ correction algorithms (OOT for GNU Radio 3.10).
{ lib , fetchFromGitHub , gnuradioPackages , cmake , pkg-config , boost , spdlog , gmp , log4cpp , volk , fftwFloat , python3Packages }:

gnuradioPackages.mkDerivation {
  pname = "gr-correctiq";
  version = "3.10";

  src = fetchFromGitHub {
    owner = "ghostop14";
    repo = "gr-correctiq";
    rev = "f1189bf9f1b4e27daa0c1fe69c6464a39cdf51c5";
    hash = "sha256-KWmbnbtlsmuhIGJ5QMWFEwfzgKa/jWhvfk00RTyqnYg=";
  };

  nativeBuildInputs = [ cmake pkg-config python3Packages.pybind11 ];
  buildInputs = [ boost spdlog gmp log4cpp volk fftwFloat python3Packages.numpy ];
  cmakeFlags = [ "-DCMAKE_POLICY_VERSION_MINIMUM=3.5" ];
  env.NIX_CFLAGS_COMPILE = "-Wno-error -Wno-deprecated-declarations -Wno-narrowing -fpermissive";

  meta = {
    description = "IQ correction algorithms";
    homepage = "https://github.com/ghostop14/gr-correctiq";
    license = lib.licenses.gpl3Plus;
    platforms = lib.platforms.linux;
  };
}
