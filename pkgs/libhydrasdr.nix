# libhydrasdr: HydraSDR RFOne device library. Not in nixpkgs; the HydraSDR
# forks (SDR++, gr-osmosdr, ...) depend on it, so we build it from source like
# RF Swift does for its .deb builds.
{ lib, stdenv, fetchFromGitHub, cmake, pkg-config, libusb1 }:

stdenv.mkDerivation {
  pname = "libhydrasdr";
  version = "unstable";

  # libhydrasdr lives in the hydrasdr-host repo (like libairspy in airspyone_host).
  src = fetchFromGitHub {
    owner = "hydrasdr";
    repo = "hydrasdr-host";
    rev = "d52f1fe695590fc4ab94ffdb0d13d9c07171a581";
    hash = "sha256-1kG5jkzHLlpfwikvf6Qs9Uoxxy4t7sIFj7sMVZUgp0U=";
  };

  nativeBuildInputs = [ cmake pkg-config ];
  buildInputs = [ libusb1 ];

  # Older cmake_minimum_required guard for CMake 4.
  cmakeFlags = [ "-DCMAKE_POLICY_VERSION_MINIMUM=3.5" "-DINSTALL_UDEV_RULES=OFF" ];

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
