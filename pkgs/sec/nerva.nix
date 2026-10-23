# nerva (praetorian-inc/nerva): Network reconnaissance and vulnerability assessment (Praetorian)
{ lib, buildGoModule, fetchFromGitHub }:

buildGoModule {
  pname = "nerva";
  version = "unstable-2026-10-23";

  src = fetchFromGitHub {
    owner = "praetorian-inc";
    repo = "nerva";
    rev = "360d891aff1f20fdc545f0a643eeb579a59f4ffd";
    hash = "sha256-iX8j0baHVaz0o/VBfXW+WUZeVGeHVGudGf9EfpCnlhg=";
  };

  vendorHash = "sha256-Fjxs+JKq9Lv9wBQEjvSlEw9cpgm/Ye1l4iqdjRa8+X8=";
  subPackages = [ "cmd/nerva" ];
  meta = {
    description = "Network reconnaissance and vulnerability assessment (Praetorian)";
    homepage = "https://github.com/praetorian-inc/nerva";
    license = lib.licenses.mit;
    platforms = lib.platforms.unix;
    mainProgram = "nerva";
  };
}
