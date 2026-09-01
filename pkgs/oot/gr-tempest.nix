# gr-tempest: Van Eck / TEMPEST monitor OOT for GNU Radio (git-artes). master is
# the GR 3.10 line (adapted Dec 2022). The compiled module needs no fosphor/faad;
# the example flowgraphs use qtgui + Pillow at runtime only.
{ lib, fetchFromGitHub, gnuradioPackages, cmake, pkg-config
, boost, spdlog, gmp, volk, fftwFloat, python3Packages }:

gnuradioPackages.mkDerivation {
  pname = "gr-tempest";
  version = "master";

  src = fetchFromGitHub {
    owner = "git-artes";
    repo = "gr-tempest";
    rev = "9df82064515d66ca83f6cc66442ddfdeaf30af83";
    hash = "sha256-7YjW07FBV7/fgDVX9sby5JS+CfwgFX5jqKhnuUmqowA=";
  };

  nativeBuildInputs = [ cmake pkg-config python3Packages.pybind11 ];
  buildInputs = [ boost spdlog gmp volk fftwFloat ]
    ++ (with python3Packages; [ numpy pillow ]);
  cmakeFlags = [ "-DCMAKE_POLICY_VERSION_MINIMUM=3.5" ];

  meta = {
    description = "GNU Radio TEMPEST (Van Eck phreaking) monitor blocks and examples";
    homepage = "https://github.com/git-artes/gr-tempest";
    license = lib.licenses.gpl3Plus;
    platforms = lib.platforms.linux;
  };
}
