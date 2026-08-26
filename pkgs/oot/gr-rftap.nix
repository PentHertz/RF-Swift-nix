# RFtap protocol-analysis blocks (OOT for GNU Radio 3.10).
{ lib , fetchFromGitHub , gnuradioPackages , cmake , pkg-config , boost , spdlog , gmp , log4cpp , volk , fftwFloat , python3Packages }:

gnuradioPackages.mkDerivation {
  pname = "gr-rftap";
  version = "3.10";

  src = fetchFromGitHub {
    owner = "FlUxIuS";
    repo = "gr-rftap";
    rev = "80f79dead921d4aa919fb2ce53075a40e7d05c89";
    hash = "sha256-5/1+Hd6RmRE97uqw5XGLwk4h++mZxH5U8cC9TESJtN8=";
  };

  nativeBuildInputs = [ cmake pkg-config python3Packages.pybind11 ];
  buildInputs = [ boost spdlog gmp log4cpp volk fftwFloat python3Packages.numpy ];
  cmakeFlags = [ "-DCMAKE_POLICY_VERSION_MINIMUM=3.5" ];
  env.NIX_CFLAGS_COMPILE = "-Wno-error -Wno-deprecated-declarations -Wno-narrowing -fpermissive";

  meta = {
    description = "RFtap protocol-analysis blocks";
    homepage = "https://github.com/FlUxIuS/gr-rftap";
    license = lib.licenses.gpl3Plus;
    platforms = lib.platforms.linux;
  };
}
