# network socket blocks (OOT for GNU Radio 3.10).
{ lib , fetchFromGitHub , gnuradioPackages , cmake , pkg-config , boost , spdlog , gmp , log4cpp , volk , fftwFloat , python3Packages, libpcap }:

gnuradioPackages.mkDerivation {
  pname = "gr-grnet";
  version = "3.10";

  src = fetchFromGitHub {
    owner = "PentHertz";
    repo = "gr-grnet_resolute";
    rev = "0a8e4bc3dc2c596dbd053eb16b29a76badf4ed56";
    hash = "sha256-8t4R/+HNQpXnxDCod5xXaxej/TtoqHatYdJ6hnzumHA=";
  };

  nativeBuildInputs = [ cmake pkg-config python3Packages.pybind11 ];
  buildInputs = [ boost spdlog gmp log4cpp volk fftwFloat python3Packages.numpy libpcap ];
  cmakeFlags = [ "-DCMAKE_POLICY_VERSION_MINIMUM=3.5" ];
  env.NIX_CFLAGS_COMPILE = "-Wno-error -Wno-deprecated-declarations -Wno-narrowing -fpermissive";

  meta = {
    description = "network socket blocks";
    homepage = "https://github.com/PentHertz/gr-grnet_resolute";
    license = lib.licenses.gpl3Plus;
    platforms = lib.platforms.linux;
  };
}
