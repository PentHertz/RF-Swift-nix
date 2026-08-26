# Proxmark5: the RfidResearchGroup/Iceman client + firmware built for the
# Proxmark5 hardware (PLATFORM=PM5), exposed as `pm5`. This is deliberately
# distinct from the default PM3 build so you can reflash a Proxmark5 without
# mixing up the firmware.
{ lib, fetchFromGitHub, proxmark3 }:

proxmark3.overrideAttrs (old: {
  pname = "proxmark5";
  version = "unstable-pm5";

  # nixpkgs' proxmark3 is too old to know PLATFORM=PM5 (Proxmark5 / Artery
  # AT32F435). Pin the upstream revision: using the moving master branch made
  # this fixed-output derivation fail whenever upstream advanced.
  src = fetchFromGitHub {
    owner = "RfidResearchGroup";
    repo = "proxmark3";
    rev = "3eb0d1c7859b5fc9a038f88ec7eecd0f99084baf";
    hash = "sha256-k7M/uS5PR+gvpazl5g6K30qHEVVKN3D40jxIx2QSY48=";
  };

  # Build for the Proxmark5 hardware.
  makeFlags = (old.makeFlags or [ ]) ++ [ "PLATFORM=PM5" ];

  postInstall = (old.postInstall or "") + ''
    # Provide pm5 entry points distinct from pm3.
    if [ -e "$out/bin/proxmark3" ]; then ln -sf proxmark3 "$out/bin/pm5"; fi
    if [ -e "$out/bin/pm3" ]; then ln -sf pm3 "$out/bin/pm5-cli"; fi
  '';

  meta = (old.meta or { }) // {
    description = "Proxmark3 RRG/Iceman client + firmware built for Proxmark5 (PLATFORM=PM5)";
    mainProgram = "pm5";
  };
})
