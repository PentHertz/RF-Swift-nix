# brutus (praetorian-inc/brutus): Credential brute-forcing tool (Praetorian)
{ lib, buildGoModule, fetchFromGitHub }:

buildGoModule {
  pname = "brutus";
  version = "unstable-2026-10-14";

  src = fetchFromGitHub {
    owner = "praetorian-inc";
    repo = "brutus";
    rev = "7bc9e5d0ee418655af77c30b2fff9a292f1d6379";
    hash = "sha256-JRL7gJsv2hYCGwXoGKfsS+DCuYbnnh65F9GKtrOFK54=";
  };

  vendorHash = "sha256-fFBnqZljp+ykDTtqVIS4AxdFVcd9Mmqv/oJR4LVEq5w=";
  subPackages = [ "cmd/brutus" ];
  meta = {
    description = "Credential brute-forcing tool (Praetorian)";
    homepage = "https://github.com/praetorian-inc/brutus";
    license = lib.licenses.mit;
    platforms = lib.platforms.unix;
    mainProgram = "brutus";
  };
}
