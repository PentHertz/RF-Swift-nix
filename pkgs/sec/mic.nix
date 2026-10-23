# mic (djnnvx/mic): Minimal interface capture / network utility
{ lib, buildGoModule, fetchFromGitHub }:

buildGoModule {
  pname = "mic";
  version = "unstable-2026-09-05";

  src = fetchFromGitHub {
    owner = "djnnvx";
    repo = "mic";
    rev = "e13ecc54d93872b9fc414a6b395cf41935ac1ceb";
    hash = "sha256-tZVr+CmG7UohtKc+um5lG8uG+s2MVP2vv2Yhe7dH+p0=";
  };

  vendorHash = "sha256-JuP7Ghfgbf+2BGmrC7cW0Ik/5lRVVowiBkXEaUPOnM4=";

  meta = {
    description = "Minimal interface capture / network utility";
    homepage = "https://github.com/djnnvx/mic";
    license = lib.licenses.mit;
    platforms = lib.platforms.unix;
    mainProgram = "mic";
  };
}
