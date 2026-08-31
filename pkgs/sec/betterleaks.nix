# betterleaks (betterleaks/betterleaks): Secret/credential leak scanner
{ lib, buildGoModule, fetchFromGitHub, git }:

buildGoModule {
  pname = "betterleaks";
  version = "unstable-2026-08-30";

  src = fetchFromGitHub {
    owner = "betterleaks";
    repo = "betterleaks";
    rev = "2ba7943682b82a3659a89dae8fc680de1ef6b781";
    hash = "sha256-72G3fcZz3j9qyqK9PN39+CRm4/Cy/p1lIXEmyCMZkHQ=";
  };

  vendorHash = "sha256-Nr6l1AULi6pjUCy4RVQZT02Kd9yRkJLZHWCbWpCoDDY=";

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
