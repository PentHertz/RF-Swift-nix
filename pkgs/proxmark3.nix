# RRG/Iceman Proxmark3 client pinned to the same protocol revision shipped by
# the RF Swift RFID container. Client and flashed firmware must use compatible
# capabilities structures; nixpkgs 4.21128 is too old for current RF Swift PM3s.
{ lib, fetchFromGitHub, proxmark3Base }:

proxmark3Base.overrideAttrs (old: {
  pname = "proxmark3";
  version = "4.21611-1293-47d0a8fa0";

  src = fetchFromGitHub {
    owner = "RfidResearchGroup";
    repo = "proxmark3";
    rev = "47d0a8fa00ee53d3f93c9fe00fb1a44b8180e3d3";
    hash = "sha256-KaVrxN1auBJ0XVpWRynY4gbwuC2YhYokklah3lAJkJU=";
  };

  meta = (old.meta or { }) // {
    description = "Pinned RRG/Iceman Proxmark3 client matching RF Swift container firmware";
    mainProgram = "pm3";
  };
})
