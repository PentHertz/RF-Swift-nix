# car key-fob signal analyzer (OOT for GNU Radio 3.10).
{ lib , fetchFromGitHub , gnuradioPackages , cmake , pkg-config , boost , spdlog , gmp , log4cpp , volk , fftwFloat , python3Packages }:

gnuradioPackages.mkDerivation {
  pname = "gr-keyfob";
  version = "3.10";

  src = fetchFromGitHub {
    owner = "bastibl";
    repo = "gr-keyfob";
    rev = "e9b144e50dac0aeb81708dc9ae80fcb044c670d3";
    hash = "sha256-rAyGLbrdPkhcD6Jn8BIqqiRURjgNOZS4lR6LXMTEsLQ=";
  };

  nativeBuildInputs = [ cmake pkg-config python3Packages.pybind11 ];
  buildInputs = [ boost spdlog gmp log4cpp volk fftwFloat python3Packages.numpy ];
  cmakeFlags = [ "-DCMAKE_POLICY_VERSION_MINIMUM=3.5" ];
  env.NIX_CFLAGS_COMPILE = "-Wno-error -Wno-deprecated-declarations -Wno-narrowing -fpermissive";

  meta = {
    description = "car key-fob signal analyzer";
    homepage = "https://github.com/bastibl/gr-keyfob";
    license = lib.licenses.gpl3Plus;
    platforms = lib.platforms.linux;
  };
}
