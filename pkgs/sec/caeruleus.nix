# caeruleus: Bluetooth Low Energy reconnaissance tool (Praetorian). Go binary.
{ lib, buildGoModule, fetchFromGitHub }:

buildGoModule {
  pname = "caeruleus";
  version = "unstable";

  src = fetchFromGitHub {
    owner = "praetorian-inc";
    repo = "caeruleus";
    rev = "main";
    hash = "sha256-rNuHBD6ReeJDfeiWnZW8JCjJavSTntTBhmMaL1qXmVk=";
  };

  vendorHash = "sha256-WTTcJ16QOqFBJ3TNC+WgyGgqgH/twTKeY0YfvFl04pM=";
  subPackages = [ "cmd/caeruleus" ];

  meta = {
    description = "Bluetooth Low Energy reconnaissance tool";
    homepage = "https://github.com/praetorian-inc/caeruleus";
    license = lib.licenses.asl20;
    platforms = lib.platforms.linux;
    mainProgram = "caeruleus";
  };
}
