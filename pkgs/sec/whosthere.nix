# whosthere (ramonvermeulen/whosthere): ARP-based local network host discovery CLI
{ lib, buildGoModule, fetchFromGitHub }:

buildGoModule {
  pname = "whosthere";
  version = "unstable-2026-08-30";

  src = fetchFromGitHub {
    owner = "ramonvermeulen";
    repo = "whosthere";
    rev = "7e306d409f357e7e7280059c351b37edcc60fe33";
    hash = "sha256-9dLwmQW7ta5f/KjCi97rZs2Sz79UWlZN4zGiK/i2t2A=";
  };

  vendorHash = "sha256-V+NKo5NKFBU2t607yBBVfUNyeU+9Tmu4dTljhtEpkrc=";

  meta = {
    description = "ARP-based local network host discovery CLI";
    homepage = "https://github.com/ramonvermeulen/whosthere";
    license = lib.licenses.mit;
    platforms = lib.platforms.unix;
    mainProgram = "whosthere";
  };
}
