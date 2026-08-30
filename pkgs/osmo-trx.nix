# osmo-trx: SDR transceiver for OsmoBTS (Osmocom GSM). Autotools; built with the
# UHD device backend and the SIMD path of the host: SSE on x86_64, NEON on
# aarch64 (both are upstream configure options).
{ lib, stdenv, fetchFromGitHub, autoreconfHook, pkg-config
, libosmocore, fftwFloat, boost, uhd }:

stdenv.mkDerivation {
  pname = "osmo-trx";
  version = "1.6-unstable";

  src = fetchFromGitHub {
    owner = "osmocom";
    repo = "osmo-trx";
    rev = "80c54268fc871bd177a8f9482858f55832b7aa3e";
    hash = "sha256-Ovyb1NRkRscBOrnnPnG7mXh+48zaGAakW+ACKDQLNgE=";
  };

  nativeBuildInputs = [ autoreconfHook pkg-config ];
  buildInputs = [ libosmocore fftwFloat boost uhd ];

  # --with-neon is for 32-bit ARM (it adds -mfpu=neon, which the aarch64 gcc
  # rejects); on aarch64 build the portable C path.
  configureFlags = [ "--with-uhd" ]
    ++ lib.optionals stdenv.hostPlatform.isx86_64 [ "--with-sse" ];
  env.NIX_CFLAGS_COMPILE = "-Wno-error";

  meta = {
    description = "SDR transceiver for OsmoBTS (Osmocom GSM base station)";
    homepage = "https://osmocom.org/projects/osmotrx";
    license = lib.licenses.agpl3Plus;
    platforms = [ "x86_64-linux" "aarch64-linux" ];
    mainProgram = "osmo-trx-uhd";
  };
}
