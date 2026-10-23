# RRG/Iceman Proxmark3 client pinned to the same protocol revision shipped by
# the RF Swift RFID container. Client and flashed firmware must use compatible
# capabilities structures; nixpkgs 4.21128 is too old for current RF Swift PM3s.
{ lib, fetchFromGitHub, proxmark3Base }:

proxmark3Base.overrideAttrs (old: {
  pname = "proxmark3";
  version = "4.23346-211-6ce4ec49c";

  src = fetchFromGitHub {
    owner = "RfidResearchGroup";
    repo = "proxmark3";
    rev = "6ce4ec49c1d621cd2daf6265e9fc1d442747ab15";
    hash = "sha256-NKGibXkaRA7ukpb6+P4qMoA/mh3oIBQc9jtEfp//CZE=";
  };

  meta = (old.meta or { }) // {
    description = "Pinned RRG/Iceman Proxmark3 client matching RF Swift container firmware";
    mainProgram = "pm3";
  };
})
