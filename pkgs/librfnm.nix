# librfnm: host library for the RFNM SDR (rfnm), USB via libusb, logging via
# spdlog. Matches the sdrsa_devices image's rfnm_devices_install (which builds
# it from source with cmake). SoapyRFNM (soapy-rfnm) builds on top of it.
{ lib, stdenv, fetchFromGitHub, cmake, pkg-config, spdlog, libusb1 }:

stdenv.mkDerivation {
  pname = "librfnm";
  version = "unstable-rfnm";

  src = fetchFromGitHub {
    owner = "rfnm";
    repo = "librfnm";
    rev = "86bcec9cb64bd620d2857558d3245cef50e08f20";
    hash = "sha256-dFmEorWWOOHClqTeH1Rjfn3PBXryIvbMrBRLNfDGt+E=";
  };

  # rx_stream.cpp uses std::memcpy without <cstring> (libc++ on macOS leaks it,
  # libstdc++/gcc on Linux does not).
  postPatch = ''
    find src -name '*.cpp' -exec sed -i '1i #include <cstring>' {} +
  '';

  nativeBuildInputs = [ cmake pkg-config ];
  buildInputs = [ spdlog ];
  # librfnm.pc declares `Requires: libusb-1.0`, so every pkg-config consumer
  # (soapy-rfnm) needs libusb's .pc visible too: propagate it.
  propagatedBuildInputs = [ libusb1 ];
  # Its librfnm.pc composes "${prefix}/@CMAKE_INSTALL_LIBDIR@"; with the absolute
  # lib/include dirs Nix's cmake hook passes that doubles the store path, which
  # breaks pkg-config consumers (soapy-rfnm). Keep the install dirs relative.
  cmakeFlags = [
    "-DCMAKE_INSTALL_LIBDIR=lib"
    "-DCMAKE_INSTALL_INCLUDEDIR=include"
    "-DCMAKE_POLICY_VERSION_MINIMUM=3.5"
  ];

  meta = {
    description = "RFNM SDR host library";
    homepage = "https://github.com/rfnm/librfnm";
    license = lib.licenses.mit;
    platforms = lib.platforms.unix;
  };
}
