# kalibrate-hydrasdr: GSM base-station scanner / frequency-offset calibration
# tool (kal) for the HydraSDR RFOne. Part of the sdrsa_devices device layer in
# RF-Swift-images (kalibrate_hydrasdr_device). CMake; resolves the HydraSDR
# library through the CMake config libhydrasdr installs (HydraSDRConfig.cmake),
# plus FFTW3 and libusb via pkg-config. The upstream CMake would FetchContent
# hydrasdr-host from GitHub when the library is not found; that is disabled so a
# resolution failure is a build error rather than a sandbox network attempt.
{ lib, stdenv, fetchFromGitHub, cmake, pkg-config, libhydrasdr, fftw, libusb1 }:

stdenv.mkDerivation {
  pname = "kalibrate-hydrasdr";
  version = "unstable-hydrasdr";

  src = fetchFromGitHub {
    owner = "hydrasdr";
    repo = "kalibrate-hydrasdr";
    rev = "c48d50ca9ba47ce1778e2734959fdf843e72ee53";
    hash = "sha256-u4X+DSsYiAIBJj/yaHbzNSQoKL6V+tuIt2UHDIb1+34=";
  };

  nativeBuildInputs = [ cmake pkg-config ];
  buildInputs = [ libhydrasdr fftw libusb1 ];

  cmakeFlags = [
    "-DHYDRASDR_FETCH_FROM_GIT=OFF"
    "-DCMAKE_POLICY_VERSION_MINIMUM=3.5"
  ];

  meta = {
    description = "Kalibrate for HydraSDR: GSM channel scanner and oscillator offset calibration (kal)";
    homepage = "https://github.com/hydrasdr/kalibrate-hydrasdr";
    license = lib.licenses.bsd2;
    mainProgram = "kal";
    platforms = lib.platforms.unix;
  };
}
