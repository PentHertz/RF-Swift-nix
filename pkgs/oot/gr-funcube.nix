# gr-funcube: GNU Radio source/control blocks for the FUNcube Dongle Pro/Pro+
# (dl1ksv). Replaces the Ubuntu gr-funcube / libgnuradio-funcube packages the
# sdrsa_devices image installs. Talks to the dongle over HID (hidapi) and
# libusb; its FindHIDAPI only knows the Linux hidapi-libusb library name, so on
# Darwin (where nixpkgs' hidapi is a single libhidapi) the paths are pinned.
{ lib, stdenv, fetchFromGitHub, gnuradioPackages, cmake, pkg-config
, boost, spdlog, gmp, mpir, volk, hidapi, libusb1, python3Packages }:

gnuradioPackages.mkDerivation {
  pname = "gr-funcube";
  version = "unstable-2024";

  src = fetchFromGitHub {
    owner = "dl1ksv";
    repo = "gr-funcube";
    rev = "2fc05048a4a5c0be5105b2060a9daf999d8440bc";
    hash = "sha256-w6qbVpyF5wAPRd7+MSBtRgALLptsQwpyuh2HQezPXjE=";
  };

  nativeBuildInputs = [ cmake pkg-config python3Packages.pybind11 ];
  # gnuradio's block.h includes <gmpxx.h> on Linux and <mpirxx.h> on Darwin.
  buildInputs = [ boost spdlog volk hidapi libusb1 python3Packages.numpy ]
    ++ [ (if stdenv.hostPlatform.isDarwin then mpir else gmp) ];

  # Its FindHIDAPI/FindUSB only search /usr paths; point both at the Nix
  # libraries. hidapi is a single libhidapi on Darwin and split into
  # libhidapi-libusb / libhidapi-hidraw on Linux.
  cmakeFlags = [
    "-DCMAKE_POLICY_VERSION_MINIMUM=3.5"
    "-DLIBHIDAPI_INCLUDE_DIR=${hidapi}/include/hidapi"
    ("-DLIBHIDAPI_LIBRARIES=${hidapi}/lib/libhidapi"
      + lib.optionalString stdenv.hostPlatform.isLinux "-libusb"
      + stdenv.hostPlatform.extensions.sharedLibrary)
  ]
    ++ lib.optionals stdenv.hostPlatform.isLinux [
      # Its FindUSB only looks in /usr/include{,/libusb-1.0}; point it at the
      # Nix libusb (header lives under include/libusb-1.0/).
      "-DLIBUSB_INCLUDE_DIR=${lib.getDev libusb1}/include/libusb-1.0"
      "-DLIBUSB_LIBRARIES=${lib.getLib libusb1}/lib/libusb-1.0${stdenv.hostPlatform.extensions.sharedLibrary}"
    ];

  # postInstall runs in the CMake build dir; the rules file is in the source root.
  postInstall = ''
    install -Dm644 ../50-funcube.rules $out/lib/udev/rules.d/50-funcube.rules
  '';

  meta = {
    description = "GNU Radio blocks for the FUNcube Dongle Pro/Pro+";
    homepage = "https://github.com/dl1ksv/gr-funcube";
    license = lib.licenses.gpl3Plus;
    platforms = lib.platforms.unix;
  };
}
