# RRG/Iceman Proxmark3 client pinned to the same protocol revision shipped by
# the RF Swift RFID container. Client and flashed firmware must use compatible
# capabilities structures; nixpkgs 4.21128 is too old for current RF Swift PM3s.
{ lib, fetchFromGitHub, proxmark3Base }:

proxmark3Base.overrideAttrs (old: {
  pname = "proxmark3";
  version = "4.21611-797-b4c4edd7c";

  src = fetchFromGitHub {
    owner = "RfidResearchGroup";
    repo = "proxmark3";
    rev = "b4c4edd7c94a989108cacaaaf73805a28a6c217c";
    hash = "sha256-LAgI2VY2s1WGjvkGNF2OQ/JI3yUF7GRvaZqQ/IK7Ekw=";
  };

  meta = (old.meta or { }) // {
    description = "Pinned RRG/Iceman Proxmark3 client matching RF Swift container firmware";
    mainProgram = "pm3";
  };
})
