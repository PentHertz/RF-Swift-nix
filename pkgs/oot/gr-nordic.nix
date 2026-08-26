# Nordic nRF24L01+ protocol decoder (OOT for GNU Radio 3.10).
{ lib , fetchFromGitHub , gnuradioPackages , cmake , pkg-config , boost , spdlog , gmp , log4cpp , volk , fftwFloat , python3Packages }:

gnuradioPackages.mkDerivation {
  pname = "gr-nordic";
  version = "3.10";

  src = fetchFromGitHub {
    owner = "PentHertz";
    repo = "gr-nordic_resolute";
    rev = "e53c0367b58ce2b101b2a63caec797c191fb4826";
    hash = "sha256-p6RPJBgP5h4shOch+Sc6Pl5hPL+VsGnqWAn6BT9xWv4=";
  };

  nativeBuildInputs = [ cmake pkg-config python3Packages.pybind11 ];
  buildInputs = [ boost spdlog gmp log4cpp volk fftwFloat python3Packages.numpy ];
  cmakeFlags = [ "-DCMAKE_POLICY_VERSION_MINIMUM=3.5" ];
  env.NIX_CFLAGS_COMPILE = "-Wno-error -Wno-deprecated-declarations -Wno-narrowing -fpermissive";

  meta = {
    description = "Nordic nRF24L01+ protocol decoder";
    homepage = "https://github.com/PentHertz/gr-nordic_resolute";
    license = lib.licenses.gpl3Plus;
    platforms = lib.platforms.linux;
  };
}
