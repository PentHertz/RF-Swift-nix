# liblms7002m: compact LMS7002M transceiver register/control library (xtrx-sdr),
# the lowest layer of the XTRX host stack (liblms7002m -> libxtrxdsp/libxtrxll
# -> libxtrx). Generates its register header at build time with a Cheetah3
# template script, so Python with Cheetah is a build-time dependency.
{ lib, stdenv, fetchFromGitHub, cmake, python3 }:

stdenv.mkDerivation {
  pname = "liblms7002m";
  version = "unstable-xtrx";

  src = fetchFromGitHub {
    owner = "xtrx-sdr";
    repo = "liblms7002m";
    rev = "b07761b7386181f0e6a35158456b75bce14f2aca";
    hash = "sha256-tI6gm/Juvaya1D9byjwZtm7zuoKTbL+07hTgoI9UAg8=";
  };

  nativeBuildInputs = [ cmake (python3.withPackages (ps: [ ps.cheetah3 ])) ];
  cmakeFlags = [ "-DCMAKE_POLICY_VERSION_MINIMUM=3.5" ];

  meta = {
    description = "Compact LMS7002M control library (XTRX host stack)";
    homepage = "https://github.com/xtrx-sdr/liblms7002m";
    license = lib.licenses.lgpl21Plus;
    # The XTRX host stack is Linux code (glibc headers, Linux libusb/pthread
    # semantics, PCIe ioctls); it does not compile on Darwin.
    platforms = lib.platforms.linux;
  };
}
