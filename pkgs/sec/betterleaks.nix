# betterleaks (betterleaks/betterleaks): Secret/credential leak scanner
{ lib, buildGoModule, fetchFromGitHub, git }:

buildGoModule {
  pname = "betterleaks";
  version = "unstable-2026-10-20";

  src = fetchFromGitHub {
    owner = "betterleaks";
    repo = "betterleaks";
    rev = "49d0a87e9d3a4f729d88d828e6773a57bb4409b3";
    hash = "sha256-p08mIkAyjlwgC5lGKysrrkdkOWUiCl+sF+hSSvmV9D4=";
  };

  vendorHash = "sha256-SspPUCdruUMGPNNyLZZq5DU12ls3DEXFKDeShb9gm54=";

  # detect_test.go's TestFromGit / TestFromGitStaged shell out to `git`, which is
  # absent from the sandbox PATH by default: add it for the check phase.
  nativeCheckInputs = [ git ];

  meta = {
    description = "Secret/credential leak scanner";
    homepage = "https://github.com/betterleaks/betterleaks";
    license = lib.licenses.mit;
    platforms = lib.platforms.unix;
    mainProgram = "betterleaks";
  };
}
