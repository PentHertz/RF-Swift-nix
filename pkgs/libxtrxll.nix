# libxtrxll: XTRX low-level transport library (xtrx-sdr) with two backends:
# USB3380 (via libusb3380, any OS) and the Linux PCIe driver (userspace ioctl
# side of xtrx_linux_pcie_drv; the kernel module itself is out of scope for
# Nix). The PCIe backend only compiles against Linux headers, so it is enabled
# on Linux and left out elsewhere.
{ lib, stdenv, fetchFromGitHub, cmake, pkg-config, libusb3380, libusb1 }:

stdenv.mkDerivation {
  pname = "libxtrxll";
  version = "unstable-xtrx";

  src = fetchFromGitHub {
    owner = "myriadrf";
    repo = "libxtrxll";
    rev = "78fb3657b8e6aeb6977813fbbd0ba771ac16433c";
    hash = "sha256-irKXnC+m3Ecmtv8aXEZGuE9xy0apneuGUOCzu4lb/9k=";
  };

  nativeBuildInputs = [ cmake pkg-config ];
  buildInputs = [ libusb3380 libusb1 ];

  cmakeFlags = [
    "-DENABLE_PCIE=ON"
    "-DENABLE_USB3380=ON"
    "-DCMAKE_POLICY_VERSION_MINIMUM=3.5"
  ];

  meta = {
    description = "XTRX low-level transport library (USB3380 and Linux PCIe backends)";
    homepage = "https://github.com/xtrx-sdr/libxtrxll";
    license = lib.licenses.lgpl21Plus;
    platforms = lib.platforms.linux;
  };
}
