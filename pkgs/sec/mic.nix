# mic (djnnvx/mic): Minimal interface capture / network utility
{ lib, buildGoModule, fetchFromGitHub }:

buildGoModule {
  pname = "mic";
  version = "unstable-2026-08-30";

  src = fetchFromGitHub {
    owner = "djnnvx";
    repo = "mic";
    rev = "b11226c70712291699e90011ef47f25bcb121c23";
    hash = "sha256-wUiLKi0bnY6Sbv5TqAH34ZzcWE3Mq737XGw2u7DEgec=";
  };

  vendorHash = "sha256-LP4mzU5ayrOBM2eTVxadu0zTzSLebhonrPvHRaZq3UA=";

  meta = {
    description = "Minimal interface capture / network utility";
    homepage = "https://github.com/djnnvx/mic";
    license = lib.licenses.mit;
    platforms = lib.platforms.unix;
    mainProgram = "mic";
  };
}
