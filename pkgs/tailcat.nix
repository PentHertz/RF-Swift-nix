# Tailcat also serves as the reference declarative package. More complicated
# packages can continue to use regular derivations.
{ lib, callPackage }:

(callPackage ./lib/mkGitHubTool.nix { }) {
  pname = "tailcat";
  version = "0-unstable-2026-08-29";
  build = "go";
  source = {
    owner = "tailscale";
    repo = "tailcat";
    updateBranch = "main";
    rev = "88929418b1a3f3c74904a3136d6a9e87b1b5b9bb";
    hash = "sha256-+VTbYZN45gUAUq/KxidxzkDMLVUK4nVw9wqBARP+x9s=";
  };
  vendorHash = "sha256-3uVUHATnd2s+Axdq06/xAQ2IbzJZfP1yQ/nEopgckq0=";
  subPackages = [ "cmd/tailcat" ];
  description = "Netcat over Tailscale's data plane without its control plane";
  license = "bsd3";
}
