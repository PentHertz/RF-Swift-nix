# timing/synchronization utilities (Sandia) (OOT for GNU Radio 3.10).
{ lib , fetchFromGitHub , gnuradioPackages , cmake , pkg-config , boost , spdlog , gmp , log4cpp , volk , fftwFloat , python3Packages, git, gr-pdu_utils, gr-sandia_utils }:

gnuradioPackages.mkDerivation {
  pname = "gr-timing_utils";
  version = "3.10";

  src = fetchFromGitHub {
    owner = "PentHertz";
    repo = "gr-timing_utils_resolute";
    rev = "6bec46d401b0b5133c4d84bed3e5ed15bb514c36";
    hash = "sha256-RbGx4XOsrdHHBI+GZ86oR1/IK0GrmuYZ/N+cTFd2UFo=";
  };

  nativeBuildInputs = [ cmake pkg-config git python3Packages.pybind11 ];
  buildInputs = [ boost spdlog gmp log4cpp volk fftwFloat python3Packages.numpy gr-pdu_utils gr-sandia_utils ];
  # GRC definitions written for GNU Radio 3.8: pmt is a top-level module in
  # 3.10 (not gnuradio.pmt), and sandia_utils installs as gnuradio.sandia_utils.
  postPatch = ''
    substituteInPlace grc/timing_utils_time_delta.block.yml grc/timing_utils_wall_clock_time.block.yml \
      --replace-fail "imports: from gnuradio import timing_utils, pmt" "imports: from gnuradio import timing_utils; import pmt"
    substituteInPlace grc/timing_utils_timed_cordic_emulator.block.yml \
      --replace-fail "            import sandia_utils" "            from gnuradio import sandia_utils"
  '';
  cmakeFlags = [ "-DCMAKE_POLICY_VERSION_MINIMUM=3.5" ];
  env.NIX_CFLAGS_COMPILE = "-Wno-error -Wno-deprecated-declarations -Wno-narrowing -fpermissive";

  meta = {
    description = "timing/synchronization utilities (Sandia)";
    homepage = "https://github.com/PentHertz/gr-timing_utils_resolute";
    license = lib.licenses.gpl3Plus;
    platforms = lib.platforms.linux;
  };
}
