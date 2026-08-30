# usdr-lib: host library, tools and SoapySDR module for Wavelet Lab uSDR
# devices. Matches the sdrsa_devices image's usdr_lib_install (`cmake ../src`).
# The kernel driver (dkms) is out of scope; the userspace stack talks to it
# through Linux ioctls, so this is Linux-only. The Qt debug GUI, unit tests and
# Verilator simulation targets are switched off.
{ lib, stdenv, fetchFromGitHub, cmake, pkg-config, python3, libusb1, soapysdr }:

stdenv.mkDerivation {
  pname = "usdr-lib";
  version = "unstable-2025";

  src = fetchFromGitHub {
    owner = "wavelet-lab";
    repo = "usdr-lib";
    rev = "069df210e6db5716726ad8e55dfcc84a1942cd4b";
    hash = "sha256-e20GG2hCuMhnVs0GxQz5gBkBGObOy9ZZ/jiaVdxSBco=";
  };

  # CMakeLists.txt lives in src/, not the repo root.
  cmakeDir = "../src";

  nativeBuildInputs = [ cmake pkg-config (python3.withPackages (ps: [ ps.pyyaml ])) ];
  buildInputs = [ libusb1 soapysdr ];

  cmakeFlags = [
    "-DENABLE_SOAPY=ON"
    "-DENABLE_GUI=OFF"
    "-DENABLE_TESTS=OFF"
    "-DENABLE_VERILATOR=OFF"
    "-DENABLE_DMONITOR=OFF"
    "-DSoapySDR_DIR=${soapysdr}/share/cmake/SoapySDR/"
    "-DCMAKE_POLICY_VERSION_MINIMUM=3.5"
  ];

  meta = {
    description = "Wavelet Lab uSDR host library, tools and SoapySDR module";
    homepage = "https://github.com/wavelet-lab/usdr-lib";
    license = lib.licenses.mit;
    platforms = lib.platforms.linux;
  };
}
