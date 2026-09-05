# Tailcat also serves as the reference declarative package. More complicated
# packages can continue to use regular derivations.
{ lib, callPackage, buildGo127Module, go_1_27, fetchurl }:

let
  # This Tailcat revision (and its Tailscale dependency) requires Go 1.27.1.
  # The locked nixpkgs has Go 1.27.0; keep the patch release reproducible rather
  # than letting GOTOOLCHAIN download an unpinned compiler inside the sandbox.
  go = if lib.versionAtLeast go_1_27.version "1.27.1" then go_1_27 else
    go_1_27.overrideAttrs (_: {
      version = "1.27.1";
      src = fetchurl {
        url = "https://go.dev/dl/go1.27.1.src.tar.gz";
        sha256 = "4e408abae126d916b6164627193f2c54f0e3ca1312d693b86db45f862ab238b1";
      };
    });
in
(callPackage ./lib/mkGitHubTool.nix {
  buildGoModule = buildGo127Module.override { inherit go; };
}) {
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
  vendorHash = "sha256-hpFVgsUKswE7g69EieoeKGPR1nVkcRmBhDKbnB2CDBg=";
  subPackages = [ "cmd/tailcat" ];
  # The check phase would only run cmd/tailcat's suite (subPackages), and 17 of
  # its 57 tests are end-to-end: they compile a fixture binary, start a DERP
  # relay on loopback and expect a server and a client process to finish a
  # WireGuard handshake within 10 s. Inside the Nix sandbox on GitHub's runners
  # that handshake timed out in all three runs of 2026-09-05 (TestServeWithoutPSK,
  # then the forward test), while the same derivation passes on a workstation.
  # Upstream runs the suite in its own CI; this package only has to produce the
  # binary, so the suite is not run here.
  doCheck = false;
  description = "Netcat over Tailscale's data plane without its control plane";
  license = "bsd3";
}
