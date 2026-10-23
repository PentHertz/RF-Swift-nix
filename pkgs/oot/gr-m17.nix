# M17 digital voice protocol (OOT for GNU Radio 3.10).
# gr-m17 compiles the M17 reference C library from its ../libm17 git submodule
# (m17.c, decode/, encode/, math/, payload/), so fetch it with submodules.
{ lib , fetchFromGitHub , gnuradioPackages , cmake , pkg-config , boost , spdlog , gmp , log4cpp , volk , fftwFloat , python3Packages }:

gnuradioPackages.mkDerivation {
  pname = "gr-m17";
  version = "3.10";

  src = fetchFromGitHub {
    owner = "M17-Project";
    repo = "gr-m17";
    rev = "09102c857190361d9ef1fb7ad76e42bd67a0905a";
    fetchSubmodules = true;
    hash = "sha256-ViqYYZKVFeyJrBW/FkzuYPB3C6v+VD22rkSh6gwSql4=";
  };

  nativeBuildInputs = [ cmake pkg-config python3Packages.pybind11 ];
  buildInputs = [ boost spdlog gmp log4cpp volk fftwFloat python3Packages.numpy ];
  cmakeFlags = [ "-DCMAKE_POLICY_VERSION_MINIMUM=3.5" ];
  env.NIX_CFLAGS_COMPILE = "-Wno-error -Wno-deprecated-declarations -Wno-narrowing -fpermissive";

  meta = {
    description = "M17 digital voice protocol";
    homepage = "https://github.com/M17-Project/gr-m17";
    license = lib.licenses.gpl3Plus;
    platforms = lib.platforms.linux;
  };
}
