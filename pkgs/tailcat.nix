# Tailcat also serves as the reference declarative package. More complicated
# packages can continue to use regular derivations.
{ lib, callPackage }:

(callPackage ./lib/mkGitHubTool.nix { }) {
  pname = "tailcat";
  version = "0-unstable-2026-09-05";
  build = "go";
  source = {
    owner = "tailscale";
    repo = "tailcat";
    updateBranch = "main";
    rev = "5a83b9f9e119aad6b558cbc122d94efdca87452d";
    hash = "sha256-CqkNLwJUvU8IrCrEyJjCLVYEVHrzRcKNnesGbztC7So=";
  };
  vendorHash = "sha256-3uVUHATnd2s+Axdq06/xAQ2IbzJZfP1yQ/nEopgckq0=";
  subPackages = [ "cmd/tailcat" ];
  description = "Netcat over Tailscale's data plane without its control plane";
  license = "bsd3";
}
