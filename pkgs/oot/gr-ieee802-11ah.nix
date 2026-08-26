# WiFi HaLow 802.11ah sub-1GHz (OOT for GNU Radio 3.10).
{ lib , fetchFromGitHub , gnuradioPackages , cmake , pkg-config , boost , spdlog , gmp , log4cpp , volk , fftwFloat , python3Packages, gr-foo }:

gnuradioPackages.mkDerivation {
  pname = "gr-ieee802-11ah";
  version = "3.10";

  src = fetchFromGitHub {
    owner = "irongiant33";
    repo = "gr-ieee802-11ah";
    rev = "e37389d8e3208a7ba70d6d82661b97e50416ca78";
    hash = "sha256-QzdWObi/H/AzKmvzviYr7nMc9nD+bGAhU5rvDXsetYQ=";
  };

  nativeBuildInputs = [ cmake pkg-config python3Packages.pybind11 ];
  buildInputs = [ boost spdlog gmp log4cpp volk fftwFloat python3Packages.numpy gr-foo ];
  cmakeFlags = [ "-DCMAKE_POLICY_VERSION_MINIMUM=3.5" ];
  env.NIX_CFLAGS_COMPILE = "-Wno-error -Wno-deprecated-declarations -Wno-narrowing -fpermissive";

  meta = {
    description = "WiFi HaLow 802.11ah sub-1GHz";
    homepage = "https://github.com/irongiant33/gr-ieee802-11ah";
    license = lib.licenses.gpl3Plus;
    platforms = lib.platforms.linux;
  };
}
