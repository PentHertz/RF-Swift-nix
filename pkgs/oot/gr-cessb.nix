# Controlled Envelope SSB modulation (OOT for GNU Radio 3.10).
{ lib , fetchFromGitHub , gnuradioPackages , cmake , pkg-config , boost , spdlog , gmp , log4cpp , volk , fftwFloat , python3Packages }:

gnuradioPackages.mkDerivation {
  pname = "gr-cessb";
  version = "3.10";

  src = fetchFromGitHub {
    owner = "drmpeg";
    repo = "gr-cessb";
    rev = "ff40c670a507ee86793ecb24358c63032610e965";
    hash = "sha256-UvWf8x6y3jOtGkX+OSow3runJrvB3S/aKML8c2rhwRY=";
  };

  nativeBuildInputs = [ cmake pkg-config python3Packages.pybind11 ];
  buildInputs = [ boost spdlog gmp log4cpp volk fftwFloat python3Packages.numpy ];
  cmakeFlags = [ "-DCMAKE_POLICY_VERSION_MINIMUM=3.5" ];
  env.NIX_CFLAGS_COMPILE = "-Wno-error -Wno-deprecated-declarations -Wno-narrowing -fpermissive";

  meta = {
    description = "Controlled Envelope SSB modulation";
    homepage = "https://github.com/drmpeg/gr-cessb";
    license = lib.licenses.gpl3Plus;
    platforms = lib.platforms.linux;
  };
}
