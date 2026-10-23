# titus (praetorian-inc/titus): TLS/certificate reconnaissance tool (Praetorian)
{ lib, buildGoModule, fetchFromGitHub, git }:

buildGoModule {
  pname = "titus";
  version = "unstable-2026-10-20";

  src = fetchFromGitHub {
    owner = "praetorian-inc";
    repo = "titus";
    rev = "4059973d1ed963f58ebf156f372865fb60f6cd2d";
    hash = "sha256-kGP4UnEKh6oCla9XTalj+inqfVy+00diMhPcteg+oig=";
  };

  vendorHash = "sha256-CSJSOjBR6cZf2/ZczkFZDO8v3mO4AMArRasJLTt1yTM=";

  # The clone-enumerator tests shell out to `git init` (git_test.go), which is
  # absent from the sandbox PATH by default: add it for the check phase.
  nativeCheckInputs = [ git ];

  meta = {
    description = "TLS/certificate reconnaissance tool (Praetorian)";
    homepage = "https://github.com/praetorian-inc/titus";
    license = lib.licenses.mit;
    platforms = lib.platforms.unix;
    mainProgram = "titus";
  };
}
