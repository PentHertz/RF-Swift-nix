# libxtrxdsp: SIMD DSP helpers (filters, FFT, format conversion) used by
# libxtrx's sample path (xtrx-sdr). No external dependencies.
{ lib, stdenv, fetchFromGitHub, cmake }:

stdenv.mkDerivation {
  pname = "libxtrxdsp";
  version = "unstable-xtrx";

  src = fetchFromGitHub {
    owner = "myriadrf";
    repo = "libxtrxdsp";
    rev = "271f5e60e40dd578c0db5f50ceb7fd6b7119c5ef";
    hash = "sha256-I2M6Zj4PTHRBQ7AZWnBZjR9eYj8dKp1WvTWfVfVoNsg=";
  };

  nativeBuildInputs = [ cmake ];
  cmakeFlags = [ "-DCMAKE_POLICY_VERSION_MINIMUM=3.5" ];

  meta = {
    description = "DSP helper library for the XTRX host stack";
    homepage = "https://github.com/xtrx-sdr/libxtrxdsp";
    license = lib.licenses.lgpl21Plus;
    # Linux code (glibc <endian.h>); part of the Linux-only XTRX stack.
    platforms = lib.platforms.linux;
  };
}
