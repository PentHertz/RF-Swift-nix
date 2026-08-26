# gr-osmosdr, PentHertz "resolute" fork. Built by overriding the nixpkgs
# gnuradio OOT so we keep its GNU Radio build recipe and just swap the source.
{ lib, fetchFromGitHub, gnuradioPackages, libhydrasdr }:

gnuradioPackages.osmosdr.overrideAttrs (old: {
  pname = "gr-osmosdr-penthertz";
  version = "unstable-penthertz";
  src = fetchFromGitHub {
    owner = "PentHertz";
    repo = "gr-osmosdr_resolute";
    rev = "master";
    hash = "sha256-lVaVQ3hNf7UhbmXsw9FQSwfVXrTeKa5bYSRxMxJFRmw=";
  };
  buildInputs = (old.buildInputs or [ ]) ++ [ libhydrasdr ];
  meta = (old.meta or { }) // {
    description = "gr-osmosdr (PentHertz resolute fork) source/sink blocks for GNU Radio";
    homepage = "https://github.com/PentHertz/gr-osmosdr_resolute";
  };
})
