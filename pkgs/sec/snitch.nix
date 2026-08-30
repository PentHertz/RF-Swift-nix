# snitch (karol-broda/snitch): Network host/port discovery and monitoring CLI
{ lib, buildGoModule, fetchFromGitHub }:

buildGoModule {
  pname = "snitch";
  version = "unstable-2026-08-30";

  src = fetchFromGitHub {
    owner = "karol-broda";
    repo = "snitch";
    rev = "9b1d21d134f02eda61edd0fc1512cac05fd71a69";
    hash = "sha256-vdQ7Qnykx9XtCPmjttcOmTCVFhrF62qPaLXolXJ1Ln0=";
  };

  vendorHash = "sha256-fX3wOqeOgjH7AuWGxPQxJ+wbhp240CW8tiF4rVUUDzk=";

  meta = {
    description = "Network host/port discovery and monitoring CLI";
    homepage = "https://github.com/karol-broda/snitch";
    license = lib.licenses.mit;
    platforms = lib.platforms.unix;
    mainProgram = "snitch";
  };
}
