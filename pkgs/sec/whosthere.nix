# whosthere (ramonvermeulen/whosthere): ARP-based local network host discovery CLI
{ lib, buildGoModule, fetchFromGitHub }:

buildGoModule {
  pname = "whosthere";
  version = "unstable-2026-10-16";

  src = fetchFromGitHub {
    owner = "ramonvermeulen";
    repo = "whosthere";
    rev = "dce2f9e3a1549484c72841054f427d921e933f0e";
    hash = "sha256-rh+GXeTWdCcqmanlBtb1OG7UjzQFi/8d8U+bansRAuo=";
  };

  vendorHash = "sha256-f4nGolvYdJGctTkREWPVcqloQrbBjVjwXagGwjv0jB0=";

  meta = {
    description = "ARP-based local network host discovery CLI";
    homepage = "https://github.com/ramonvermeulen/whosthere";
    license = lib.licenses.mit;
    platforms = lib.platforms.unix;
    mainProgram = "whosthere";
  };
}
