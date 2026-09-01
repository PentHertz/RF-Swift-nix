# gr-osmosdr, PentHertz "resolute" fork: adds a native HydraSDR RFOne backend.
# Built against RF Swift's soapysdr-with-plugins (pkgs/default.nix) so its
# Soapy backend also reaches RFNM, XTRX, LiteX M2SDR and uSDR; gqrx and every
# GNU Radio flowgraph using osmosdr blocks inherit both.
{ lib, fetchFromGitHub, gnuradioPackages, libhydrasdr, soapysdr-with-plugins }:

(gnuradioPackages.osmosdr.override { inherit soapysdr-with-plugins; }).overrideAttrs (old: {
  pname = "gr-osmosdr-penthertz";
  version = "unstable-penthertz";
  src = fetchFromGitHub {
    owner = "PentHertz";
    repo = "gr-osmosdr_resolute";
    rev = "206fff787dcac512399189915c0f7f1c0f020223";
    hash = "sha256-lVaVQ3hNf7UhbmXsw9FQSwfVXrTeKa5bYSRxMxJFRmw=";
  };
  buildInputs = (old.buildInputs or [ ]) ++ [ libhydrasdr ];
  meta = (old.meta or { }) // {
    description = "gr-osmosdr (PentHertz resolute fork) source/sink blocks for GNU Radio";
    homepage = "https://github.com/PentHertz/gr-osmosdr_resolute";
  };
})
