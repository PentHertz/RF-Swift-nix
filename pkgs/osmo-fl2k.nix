# osmo-fl2k: turn FL2000-based USB 3.0-to-VGA adapters into a low-cost
# transmit-only SDR / DAC. Not in nixpkgs, built from source.
{ lib, stdenv, fetchFromGitHub, cmake, pkg-config, libusb1 }:

stdenv.mkDerivation rec {
  pname = "osmo-fl2k";
  version = "0.2.0";

  src = fetchFromGitHub {
    owner = "osmocom";
    repo = "osmo-fl2k";
    rev = "v${version}";
    hash = "sha256-BvJy2W/e0k2ogzW+im9qyzyHIDtA/mkSiXwBtnG6YRw=";
  };

  nativeBuildInputs = [ cmake pkg-config ];
  buildInputs = [ libusb1 ];

  # Older cmake_minimum_required; CMake 4 needs this to stay compatible.
  cmakeFlags = [ "-DCMAKE_POLICY_VERSION_MINIMUM=3.5" ];

  meta = {
    description = "Use FL2000-based USB 3.0 to VGA adapters as a low-cost SDR transmitter";
    homepage = "https://osmocom.org/projects/osmo-fl2k";
    license = lib.licenses.gpl2Plus;
    platforms = lib.platforms.linux;
  };
}
