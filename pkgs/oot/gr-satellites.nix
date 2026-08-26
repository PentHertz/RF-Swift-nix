# gr-satellites: decoder for many amateur/cubesat satellites (daniestevez), 3.10.
{ lib, fetchFromGitHub, gnuradioPackages, cmake, pkg-config
, boost, spdlog, gmp, log4cpp, volk, fftwFloat, python3Packages }:

gnuradioPackages.mkDerivation {
  pname = "gr-satellites";
  version = "5-maint-3.10";

  src = fetchFromGitHub {
    owner = "daniestevez";
    repo = "gr-satellites";
    rev = "maint-3.10";
    hash = "sha256-CZEY0mvpgpboZASJDbmu4NPyBrw4vGO1ApJAx5ozTDo=";
  };

  nativeBuildInputs = [ cmake pkg-config python3Packages.pybind11 ];
  buildInputs = [ boost spdlog gmp log4cpp volk fftwFloat ]
    ++ (with python3Packages; [ numpy construct requests pyyaml ]);
  cmakeFlags = [ "-DCMAKE_POLICY_VERSION_MINIMUM=3.5" ];

  meta = {
    description = "GNU Radio decoders for numerous amateur radio satellites";
    homepage = "https://github.com/daniestevez/gr-satellites";
    license = lib.licenses.gpl3Plus;
    platforms = lib.platforms.linux;
    mainProgram = "gr_satellites";
  };
}
