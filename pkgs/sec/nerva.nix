# nerva (praetorian-inc/nerva): Network reconnaissance and vulnerability assessment (Praetorian)
{ lib, buildGoModule, fetchFromGitHub }:

buildGoModule {
  pname = "nerva";
  version = "unstable-2026-08-30";

  src = fetchFromGitHub {
    owner = "praetorian-inc";
    repo = "nerva";
    rev = "ca91b7e5eab53b3f6f510c9d66ec5b6208b59864";
    hash = "sha256-UcGI0kEEJhxUY5KZJybKrZGtZ0aMzUz9MMx3xkclNT4=";
  };

  vendorHash = "sha256-0Io4otRsVndfpF+lV+siLDZLf6rsxsczngSYz3exmxM=";
  subPackages = [ "cmd/nerva" ];
  meta = {
    description = "Network reconnaissance and vulnerability assessment (Praetorian)";
    homepage = "https://github.com/praetorian-inc/nerva";
    license = lib.licenses.mit;
    platforms = lib.platforms.unix;
    mainProgram = "nerva";
  };
}
