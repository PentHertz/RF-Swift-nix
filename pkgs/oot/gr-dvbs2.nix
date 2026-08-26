# DVB-S2 decoder (PentHertz resolute) (OOT for GNU Radio 3.10).
{ lib , fetchFromGitHub , gnuradioPackages , cmake , pkg-config , boost , spdlog , gmp , log4cpp , volk , fftwFloat , python3Packages, libpcap, git }:

gnuradioPackages.mkDerivation {
  pname = "gr-dvbs2";
  version = "3.10";

  src = fetchFromGitHub {
    owner = "PentHertz";
    repo = "gr-dvbs2_resolute";
    rev = "fd4405ed29c3cd7e413cbc0465c19a1c2cd33dd1";
    hash = "sha256-yva5UTXx6FYUnmgC7SI64H0Vkcbx3YchQ1uz6ZeGMrA=";
  };

  nativeBuildInputs = [ cmake pkg-config git python3Packages.pybind11 python3Packages.six ];
  buildInputs = [ boost spdlog gmp log4cpp volk fftwFloat python3Packages.numpy libpcap ];
  cmakeFlags = [ "-DCMAKE_POLICY_VERSION_MINIMUM=3.5" ];
  env.NIX_CFLAGS_COMPILE = "-Wno-error -Wno-deprecated-declarations -Wno-narrowing -fpermissive";

  meta = {
    description = "DVB-S2 decoder (PentHertz resolute)";
    homepage = "https://github.com/PentHertz/gr-dvbs2_resolute";
    license = lib.licenses.gpl3Plus;
    platforms = lib.platforms.linux;
  };
}
