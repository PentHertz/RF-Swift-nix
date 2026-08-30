# libxtrx: the XTRX SDR host API (xtrx-sdr / myriadrf), plus the SoapyXTRX
# module it builds from its soapy/ subdirectory. Replaces the Ubuntu
# libxtrx-dev / soapysdr-module-xtrx packages the sdrsa_devices image installs.
# The Qt5/QCustomPlot xtrx_fft example is skipped (its find_package calls are
# optional and none of those inputs are provided).
{ lib, stdenv, fetchFromGitHub, cmake, pkg-config
, liblms7002m, libxtrxdsp, libxtrxll, soapysdr }:

stdenv.mkDerivation {
  pname = "libxtrx";
  version = "unstable-xtrx";

  src = fetchFromGitHub {
    owner = "myriadrf";
    repo = "libxtrx";
    rev = "d9599fbf5be2714e6933c5a15acb3d8c57669859";
    hash = "sha256-L/vlL8NT+uuxZ+o5/AxIkp8LcE7a+fo8QvBF/qT2h4A=";
  };

  nativeBuildInputs = [ cmake pkg-config ];
  buildInputs = [ liblms7002m libxtrxdsp libxtrxll soapysdr ];

  cmakeFlags = [
    "-DENABLE_SOAPY=ON"
    # SoapySDR's module helper installs relative to the prefix once it finds
    # the SoapySDR config; point it at the Nix one (nixpkgs' Soapy-module idiom).
    "-DSoapySDR_DIR=${soapysdr}/share/cmake/SoapySDR/"
    "-DCMAKE_POLICY_VERSION_MINIMUM=3.5"
  ];

  # The SoapySDR module must end up under this package so
  # soapysdr-with-plugins can put it on SOAPY_SDR_PLUGIN_PATH.
  doInstallCheck = true;
  installCheckPhase = ''
    runHook preInstallCheck
    ls "$out"/lib/SoapySDR/modules*/libXTRXSupport* "$out"/lib/SoapySDR/modules*/*XTRX* >/dev/null 2>&1 \
      || { echo "SoapyXTRX module not installed under $out/lib/SoapySDR"; ls -R "$out/lib" | head -50; exit 1; }
    runHook postInstallCheck
  '';

  meta = {
    description = "XTRX SDR host library and SoapyXTRX module";
    homepage = "https://github.com/xtrx-sdr/libxtrx";
    license = lib.licenses.lgpl21Plus;
    # Whole XTRX host stack is Linux-only (see liblms7002m / libxtrxll).
    platforms = lib.platforms.linux;
  };
}
