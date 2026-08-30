# brutus (praetorian-inc/brutus): Credential brute-forcing tool (Praetorian)
{ lib, buildGoModule, fetchFromGitHub }:

buildGoModule {
  pname = "brutus";
  version = "unstable-2026-08-30";

  src = fetchFromGitHub {
    owner = "praetorian-inc";
    repo = "brutus";
    rev = "dabda04ea464be2c864d5decde30794a59948855";
    hash = "sha256-lysFjSSCDKbaQHcnz4d+EF9eYzDTQrUL9i+XuOQIjns=";
  };

  vendorHash = "sha256-hROEjPeX2iKs+bPLBqtjAMWl6EWSOvriZVqhXYEtPcM=";
  subPackages = [ "cmd/brutus" ];
  meta = {
    description = "Credential brute-forcing tool (Praetorian)";
    homepage = "https://github.com/praetorian-inc/brutus";
    license = lib.licenses.mit;
    platforms = lib.platforms.unix;
    mainProgram = "brutus";
  };
}
