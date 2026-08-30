# libusb3380: userspace driver for the PLX USB3380 bridge used by the XTRX USB
# adapters (xtrx-sdr). Backs libxtrxll's USB3380 transport; plain libusb.
{ lib, stdenv, fetchFromGitHub, cmake, pkg-config, libusb1 }:

stdenv.mkDerivation {
  pname = "libusb3380";
  version = "unstable-xtrx";

  src = fetchFromGitHub {
    owner = "xtrx-sdr";
    repo = "libusb3380";
    rev = "92d102a6b13744b7151560293c896d6fff70ce3e";
    hash = "sha256-UpfzXuDMp/1nRD6UFhKHyTSIHKxqQPzMuQq3nV/a3PE=";
  };

  nativeBuildInputs = [ cmake pkg-config ];
  buildInputs = [ libusb1 ];
  cmakeFlags = [ "-DCMAKE_POLICY_VERSION_MINIMUM=3.5" ];

  meta = {
    description = "USB3380 bridge userspace library (XTRX USB transport)";
    homepage = "https://github.com/xtrx-sdr/libusb3380";
    license = lib.licenses.lgpl21Plus;
    # Linux code (glibc <endian.h>, Linux libusb call signatures).
    platforms = lib.platforms.linux;
  };
}
