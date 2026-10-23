# libhydrasdr: HydraSDR RFOne device library. Not in nixpkgs; the HydraSDR
# forks (SDR++, gr-osmosdr, ...) depend on it, so we build it from source like
# RF Swift does for its .deb builds.
{ lib, stdenv, fetchFromGitHub, cmake, pkg-config, libusb1 }:

stdenv.mkDerivation {
  pname = "libhydrasdr";
  version = "1.1.3-unstable-2026-09-11";

  # libhydrasdr lives in the hydrasdr-host repo (like libairspy in airspyone_host).
  src = fetchFromGitHub {
    owner = "hydrasdr";
    repo = "hydrasdr-host";
    rev = "16942cbcbde47198abc6b7968c700ed0cbb8cc87";
    hash = "sha256-1dOpDtc5MzSdOcuSj2R2EEULjPlCD+PNvx/Q9/HBRTI=";
  };

  nativeBuildInputs = [ cmake pkg-config ];
  buildInputs = [ libusb1 ];

  # Older cmake_minimum_required guard for CMake 4. Keep the CMake udev-rules
  # install OFF (it targets an absolute system path and is Linux-only, which is
  # why it was disabled to keep the macOS build working); instead install the
  # repo's own rules file into the output on Linux, so `rfswift nix udev` covers
  # HydraSDR (VID 38af, legacy 1d50:60a1, and DFU 1fc9:000c) without breaking
  # Darwin.
  cmakeFlags = [ "-DCMAKE_POLICY_VERSION_MINIMUM=3.5" "-DINSTALL_UDEV_RULES=OFF" ];

  postInstall = lib.optionalString stdenv.hostPlatform.isLinux ''
    install -Dm444 ../hydrasdr-tools/51-hydrasdr.rules \
      $out/lib/udev/rules.d/51-hydrasdr.rules
  '';

  meta = {
    description = "HydraSDR RFOne device library";
    homepage = "https://github.com/hydrasdr/libhydrasdr";
    license = lib.licenses.gpl2Plus;
    # libusb + cmake, no Linux-only bits (udev rules disabled above), so it
    # builds on macOS too. Linux-only here made every hydrasdr-dependent SDR
    # tool (sdrpp-hydrasdr, gnuradio-rfswift, inspectrum-hydrasdr,
    # gr-osmosdr-penthertz) refuse to evaluate on Darwin, breaking the whole
    # SDR environment on macOS.
    platforms = lib.platforms.unix;
  };
}
