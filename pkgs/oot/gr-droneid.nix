# DJI DroneID / RemoteID decoder (OOT for GNU Radio 3.10).
{ lib , fetchFromGitHub , gnuradioPackages , cmake , pkg-config , boost , spdlog , gmp , log4cpp , volk , fftwFloat , python3Packages, turbofec, libtool, crcpp }:

gnuradioPackages.mkDerivation {
  pname = "gr-droneid";
  version = "3.10";

  src = fetchFromGitHub {
    owner = "PentHertz";
    repo = "dji_droneid_rfswift";
    rev = "f193f9c652c1ac7595a94f9ccf2256fcec13157b";
    hash = "sha256-t2Av9y3sr55Zdy5+0as4mat0jf0UOgJEZQL7xUBNRW8=";
  };
  sourceRoot = "source/gnuradio/gr-droneid";

  nativeBuildInputs = [ cmake pkg-config libtool python3Packages.pybind11 ];
  buildInputs = [ boost spdlog gmp log4cpp volk fftwFloat python3Packages.numpy turbofec ];
  cmakeFlags = [ "-DCMAKE_POLICY_VERSION_MINIMUM=3.5" ];
  env.NIX_CFLAGS_COMPILE = "-Wno-error -Wno-deprecated-declarations -Wno-narrowing -fpermissive -I${crcpp}/include";

  meta = {
    description = "DJI DroneID / RemoteID decoder";
    homepage = "https://github.com/PentHertz/dji_droneid_rfswift";
    license = lib.licenses.gpl3Plus;
    platforms = lib.platforms.linux;
  };
}
