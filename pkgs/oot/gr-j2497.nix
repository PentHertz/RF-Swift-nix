# J2497 / MIL-STD decoder (OOT for GNU Radio 3.10).
{ lib , fetchFromGitHub , gnuradioPackages , cmake , pkg-config , boost , spdlog , gmp , log4cpp , volk , fftwFloat , python3Packages }:

gnuradioPackages.mkDerivation {
  pname = "gr-j2497";
  version = "3.10";

  src = fetchFromGitHub {
    owner = "ainfosec";
    repo = "gr-j2497";
    rev = "a340034aa046c8d9fdad870da353f9e53102c02e";
    hash = "sha256-tsIMvsf47RBnJmUEe/qmK5bgsNN6eN3MVuwtDBt+LkE=";
  };

  nativeBuildInputs = [ cmake pkg-config python3Packages.pybind11 ];
  buildInputs = [ boost spdlog gmp log4cpp volk fftwFloat python3Packages.numpy ];
  cmakeFlags = [ "-DCMAKE_POLICY_VERSION_MINIMUM=3.5" ];
  env.NIX_CFLAGS_COMPILE = "-Wno-error -Wno-deprecated-declarations -Wno-narrowing -fpermissive";

  meta = {
    description = "J2497 / MIL-STD decoder";
    homepage = "https://github.com/ainfosec/gr-j2497";
    license = lib.licenses.gpl3Plus;
    platforms = lib.platforms.linux;
  };
}
