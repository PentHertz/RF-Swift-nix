# gr-iridium: Iridium burst detector/demodulator OOT for GNU Radio (muccc).
{ lib, fetchFromGitHub, gnuradioPackages, cmake, pkg-config
, boost, spdlog, gmp, log4cpp, volk, fftwFloat, python3Packages }:

gnuradioPackages.mkDerivation {
  pname = "gr-iridium";
  version = "1.0.0";

  src = fetchFromGitHub {
    owner = "muccc";
    repo = "gr-iridium";
    rev = "v1.0.0";
    hash = "sha256-XpaS1DRiQypYACEVvjgWComUpU/MDKWfP7xSAKdZQEI=";
  };

  nativeBuildInputs = [ cmake pkg-config python3Packages.pybind11 ];
  buildInputs = [ boost spdlog gmp log4cpp volk fftwFloat python3Packages.numpy ];
  cmakeFlags = [ "-DCMAKE_POLICY_VERSION_MINIMUM=3.5" ];

  # get_python_lib.py uses distutils, removed in Python 3.14, so it crashes and
  # GR_PYTHON_DIR comes back empty -> the module installs to /iridium (outside
  # $out) and the build fails. Port the script to sysconfig.
  postPatch = ''
    substituteInPlace python/get_python_lib.py \
      --replace-fail "from distutils.sysconfig import get_python_lib" "from sysconfig import get_path" \
      --replace-fail "get_python_lib(plat_specific=True, prefix=prefix)" "get_path('platlib', vars={'base': prefix, 'platbase': prefix})"
  '';

  meta = {
    description = "Iridium burst detection and demodulation blocks for GNU Radio";
    homepage = "https://github.com/muccc/gr-iridium";
    license = lib.licenses.gpl3Plus;
    platforms = lib.platforms.linux;
    mainProgram = "iridium-extractor";
  };
}
