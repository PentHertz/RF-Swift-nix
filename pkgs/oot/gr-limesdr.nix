# gr-limesdr: LimeSDR source/sink OOT for GNU Radio. myriadrf upstream, gr-3.10
# branch (master targets only GR 3.7/3.8). Links classic LimeSuite (LMS_ API).
{ lib, fetchFromGitHub, gnuradioPackages, cmake, pkg-config
, boost, spdlog, gmp, volk, limesuite, python3Packages }:

gnuradioPackages.mkDerivation {
  pname = "gr-limesdr";
  version = "gr-3.10";

  src = fetchFromGitHub {
    owner = "myriadrf";
    repo = "gr-limesdr";
    rev = "gr-3.10";
    hash = "sha256-7in7iNHFcGrTC7l3xzeKIQ5TX4XT1+H3vJXdNs9CV8g=";
  };

  nativeBuildInputs = [ cmake pkg-config python3Packages.pybind11 ];
  buildInputs = [ boost spdlog gmp volk limesuite python3Packages.numpy ];
  cmakeFlags = [ "-DCMAKE_POLICY_VERSION_MINIMUM=3.5" ];

  meta = {
    description = "GNU Radio source/sink blocks for LimeSDR (classic LimeSuite)";
    homepage = "https://github.com/myriadrf/gr-limesdr";
    license = lib.licenses.gpl3Plus;
    platforms = lib.platforms.linux;
  };
}
