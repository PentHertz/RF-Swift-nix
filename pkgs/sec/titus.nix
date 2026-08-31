# titus (praetorian-inc/titus): TLS/certificate reconnaissance tool (Praetorian)
{ lib, buildGoModule, fetchFromGitHub, git }:

buildGoModule {
  pname = "titus";
  version = "unstable-2026-08-30";

  src = fetchFromGitHub {
    owner = "praetorian-inc";
    repo = "titus";
    rev = "b4f205c445c641589df71d40c665080bc8061bb7";
    hash = "sha256-z6oJrld2lg/lI6mrfb8/YAQNRUuiFFP9RtCukioSoNM=";
  };

  vendorHash = "sha256-1kJeOd9laPbGBQP4hDKg5t4rVy0NqUG4QZj9LupV7+c=";

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
