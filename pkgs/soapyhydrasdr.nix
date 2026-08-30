# SoapyHydraSDR: SoapySDR module for the HydraSDR RFOne (PentHertz fork), on
# libhydrasdr. Matches the sdr_light image's hydrasdr_rfone_soapy_install.
# Its FindLibHYDRASDR resolves the Nix libhydrasdr through pkg-config.
{ lib, stdenv, fetchFromGitHub, cmake, pkg-config, soapysdr, libhydrasdr }:

stdenv.mkDerivation {
  pname = "soapyhydrasdr";
  version = "unstable-penthertz";

  src = fetchFromGitHub {
    owner = "PentHertz";
    repo = "SoapyHydraSDR";
    rev = "98b45201a9695ef5d12a6af35eb8485aeab4ae4b";
    hash = "sha256-DqvINsClxKs6NoFHZbfSoxPpBs4Pgjoa0skcMGyFtvA=";
  };

  nativeBuildInputs = [ cmake pkg-config ];
  buildInputs = [ soapysdr libhydrasdr ];
  # The fork computes its module dir itself (pkg-config moduledir, else a
  # hardcoded /usr/local on macOS) instead of SoapySDR's prefix-relative helper;
  # set it explicitly so the module lands under $out, where
  # soapysdr-with-plugins expects it.
  cmakeFlags = [
    "-DSoapySDR_DIR=${soapysdr}/share/cmake/SoapySDR/"
    "-DSOAPY_SDR_MODULE_DIR=lib/SoapySDR/modules${soapysdr.passthru.abiVersion}"
    "-DCMAKE_POLICY_VERSION_MINIMUM=3.5"
  ];

  meta = {
    description = "SoapySDR module for HydraSDR RFOne devices";
    homepage = "https://github.com/PentHertz/SoapyHydraSDR";
    license = lib.licenses.mit;
    platforms = lib.platforms.unix;
  };
}
