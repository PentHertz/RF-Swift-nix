# soapybladerf-srsran: FlUxIuS's SoapyBladeRF fork tuned for srsRAN's bladeRF
# radio path (what the telecom_5G_bladerf image installs in place of the stock
# SoapyBladeRF). Registers the same "bladerf" Soapy driver as the stock module,
# so it is used only in the dedicated bladeRF 5G environment through a plugin
# set that swaps the stock module out (soapysdr-with-plugins-bladerf-srsran).
{ lib, stdenv, fetchFromGitHub, cmake, pkg-config, libbladeRF, soapysdr }:

stdenv.mkDerivation {
  pname = "soapybladerf-srsran";
  version = "unstable-fluxius";

  src = fetchFromGitHub {
    owner = "FlUxIuS";
    repo = "SoapyBladeRF_srsran";
    rev = "06ca5eff76cf3958aac199614c2bffd82ed50ba7";
    hash = "sha256-XXR3YheY+Itl19iQUcFIqOd4jj9uqjPZTqBRZnA3Y18=";
  };

  nativeBuildInputs = [ cmake pkg-config ];
  buildInputs = [ libbladeRF soapysdr ];
  cmakeFlags = [
    "-DSoapySDR_DIR=${soapysdr}/share/cmake/SoapySDR/"
    "-DCMAKE_POLICY_VERSION_MINIMUM=3.5"
  ];

  meta = {
    description = "SoapySDR bladeRF module tuned for srsRAN (FlUxIuS fork)";
    homepage = "https://github.com/FlUxIuS/SoapyBladeRF_srsran";
    license = lib.licenses.lgpl21Plus;
    platforms = lib.platforms.unix;
  };
}
