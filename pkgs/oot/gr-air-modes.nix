# Mode-S / ADS-B receiver (bkerler 3.10 fork).
{ lib, fetchFromGitHub, gnuradioPackages, cmake, pkg-config
, boost, spdlog, gmp, log4cpp, volk, fftwFloat, python3Packages }:

gnuradioPackages.mkDerivation {
  pname = "gr-air-modes";
  version = "maint-3.10";

  src = fetchFromGitHub {
    owner = "bkerler";
    repo = "gr-air-modes";
    rev = "3a946c55f74da8395158b43fc69aab3902432aca";
    hash = "sha256-HuQvK2anVcU7+JxZvOKNJhMwj8C8lYDbauMKX/Aus1E=";
  };

  nativeBuildInputs = [ cmake pkg-config python3Packages.pybind11 ];
  buildInputs = [ boost spdlog gmp log4cpp volk fftwFloat python3Packages.numpy ];
  # Python modules its apps and air_modes package import at run time:
  # propagated so a GNU Radio wrapper bundling the module adds them.
  propagatedBuildInputs = with python3Packages; [ pyzmq scipy ];
  # numpy 2 removed the numpy.float alias (the builtin float is the same dtype);
  # without this, importing air_modes (so modes_rx) fails.
  postPatch = ''
    substituteInPlace python/mlat.py --replace-fail "dtype=numpy.float)" "dtype=float)"
  '';
  cmakeFlags = [ "-DCMAKE_POLICY_VERSION_MINIMUM=3.5" ];

  meta = {
    description = "Mode-S / ADS-B receiver (bkerler 3.10 fork)";
    homepage = "https://github.com/bkerler/gr-air-modes";
    license = lib.licenses.gpl3Plus;
    platforms = lib.platforms.linux;
  };
}
