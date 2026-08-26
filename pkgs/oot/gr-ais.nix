# gr-ais: AIS (marine vessel) receiver OOT for GNU Radio. bkerler's maint-3.10
# fork is the clean GR 3.10 port (upstream bistromath is stuck on 3.8).
{ lib, fetchFromGitHub, gnuradioPackages, cmake, pkg-config
, boost, spdlog, gmp, volk, fftwFloat, python3Packages }:

gnuradioPackages.mkDerivation {
  pname = "gr-ais";
  version = "maint-3.10";

  src = fetchFromGitHub {
    owner = "bkerler";
    repo = "gr-ais";
    rev = "maint-3.10";
    hash = "sha256-Q/rSQHN5zwxIOWMK8MgXn4VVeCt+NS7i3UD/Th4SyA8=";
  };

  nativeBuildInputs = [ cmake pkg-config python3Packages.pybind11 ];
  buildInputs = [ boost spdlog gmp volk fftwFloat python3Packages.numpy ];
  cmakeFlags = [ "-DCMAKE_POLICY_VERSION_MINIMUM=3.5" ];

  meta = {
    description = "GNU Radio blocks to receive and decode AIS (marine AIS) transmissions";
    homepage = "https://github.com/bkerler/gr-ais";
    license = lib.licenses.gpl3Plus;
    platforms = lib.platforms.linux;
  };
}
