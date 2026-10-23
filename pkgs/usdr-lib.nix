# usdr-lib: host library, tools and SoapySDR module for Wavelet Lab uSDR
# devices. Matches the sdrsa_devices image's usdr_lib_install (`cmake ../src`).
# The kernel driver (dkms) is out of scope; the userspace stack talks to it
# through Linux ioctls, so this is Linux-only. The Qt debug GUI, unit tests and
# Verilator simulation targets are switched off.
{ lib, stdenv, fetchFromGitHub, cmake, pkg-config, python3, libusb1, soapysdr }:

stdenv.mkDerivation {
  pname = "usdr-lib";
  version = "unstable-2026-10-23";

  src = fetchFromGitHub {
    owner = "wavelet-lab";
    repo = "usdr-lib";
    rev = "f4ff96d59aa13e6aea45108e16fb95a4c69d887c";
    hash = "sha256-lWNRtfXAWnubXZshCqpgIihmvw/pIy1XgelyBiSTPP8=";
  };

  # CMakeLists.txt lives in src/, not the repo root.
  cmakeDir = "../src";

  # usdr.pc.in prefixes ${prefix} to the (absolute, under Nix) install dirs and
  # puts libdir under bin/; use the full dirs instead.
  postPatch = ''
    substituteInPlace src/cmake/usdr.pc.in \
      --replace-fail 'exec_prefix=''${prefix}/@CMAKE_INSTALL_BINDIR@' 'exec_prefix=''${prefix}' \
      --replace-fail 'libdir=''${exec_prefix}/@CMAKE_INSTALL_LIBDIR@' 'libdir=@CMAKE_INSTALL_FULL_LIBDIR@' \
      --replace-fail 'includedir=''${prefix}/@CMAKE_INSTALL_INCLUDEDIR@/usdr' 'includedir=@CMAKE_INSTALL_FULL_INCLUDEDIR@/usdr'
  '';

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
