# NFC blocks for GNU Radio (PentHertz).
{ lib, fetchFromGitHub, gnuradioPackages, cmake, pkg-config
, boost, spdlog, gmp, log4cpp, volk, fftwFloat, python3Packages }:

gnuradioPackages.mkDerivation {
  pname = "gr-nfc";
  version = "maint-3.10";

  src = fetchFromGitHub {
    owner = "FlUxIuS";
    repo = "gr-nfc";
    rev = "8073221786ac325068f1783093bcd7f5cf54422a";
    hash = "sha256-dF0JpxdAAf8lH4RybKZ96X2JvHwaw8xMET4Hebm9czU=";
  };

  nativeBuildInputs = [ cmake pkg-config python3Packages.pybind11 ];
  buildInputs = [ boost spdlog gmp log4cpp volk fftwFloat python3Packages.numpy ];
  cmakeFlags = [ "-DCMAKE_POLICY_VERSION_MINIMUM=3.5" ];

  meta = {
    description = "NFC blocks for GNU Radio (PentHertz)";
    homepage = "https://github.com/FlUxIuS/gr-nfc";
    license = lib.licenses.gpl3Plus;
    platforms = lib.platforms.linux;
  };
}
