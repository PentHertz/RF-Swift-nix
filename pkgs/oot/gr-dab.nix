# gr-dab: DAB / DAB+ digital radio OOT for GNU Radio (andrmuel, the original
# author). master is the GR 3.10 line. Reed-Solomon is vendored in-tree; the only
# special external dep is faad2 (HE-AAC decode for DAB+).
{ lib, fetchFromGitHub, gnuradioPackages, cmake, pkg-config, perl
, boost, spdlog, gmp, volk, fftwFloat, faad2, python3Packages }:

gnuradioPackages.mkDerivation {
  pname = "gr-dab";
  version = "master";

  src = fetchFromGitHub {
    owner = "andrmuel";
    repo = "gr-dab";
    rev = "fdf26cb38ff931dcb297cc03cbe8d43f7360fbd8";
    hash = "sha256-tb6Eexsdqmwva7O6hnjuIPo8RkfZYsP22wTE2+LqzGQ=";
  };

  nativeBuildInputs = [ cmake pkg-config perl python3Packages.pybind11 ];
  buildInputs = [ boost spdlog gmp volk fftwFloat faad2 python3Packages.numpy ];
  cmakeFlags = [ "-DCMAKE_POLICY_VERSION_MINIMUM=3.5" ];

  # adjustment_gui is a .grc flowgraph compiled with grcc at build time, which
  # can't resolve the OOT blocks inside the sandbox (same as gr-gsm). Drop that
  # one GUI app; the plain-Python DAB apps (receive_dabplus.py, get_channels.py,
  # curses_app.py, ...) still install and the blocks work in gnuradio-companion.
  postPatch = ''
    perl -0777 -i -pe 's/add_custom_command\(OUTPUT adjustment_gui\.py.*?add_custom_target\(run ALL DEPENDS \$\{CMAKE_BINARY_DIR\}\/python\/app\/adjustment_gui\.py\)//s' python/app/CMakeLists.txt
    # The perl block above removes the only other reference; drop the install entry.
    perl -ni -e 'print unless /adjustment_gui\.py/' python/app/CMakeLists.txt
  '';

  meta = {
    description = "GNU Radio DAB/DAB+ digital radio receiver blocks";
    homepage = "https://github.com/andrmuel/gr-dab";
    license = lib.licenses.gpl3Plus;
    platforms = lib.platforms.linux;
  };
}
