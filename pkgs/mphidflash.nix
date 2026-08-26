# mphidflash: command-line flasher for the Microchip USB HID bootloader
# (AdamLaurie's fork, as used by RF Swift). Small C tool; the Linux backend uses
# the legacy libusb-0.1 API (libusb-compat).
{ lib, stdenv, fetchFromGitHub, libusb-compat }:

stdenv.mkDerivation {
  pname = "mphidflash";
  version = "1.6-unstable";

  src = fetchFromGitHub {
    owner = "AdamLaurie";
    repo = "mphidflash";
    rev = "master";
    hash = "sha256-akQjkkbGxkurBifTZuI+iVs8O2i8MM0LgMUYztg5hzE=";
  };

  buildInputs = [ libusb-compat ];
  env.NIX_CFLAGS_COMPILE = "-Wno-error";

  # The upstream Makefile targets 32/64-bit installs with macOS-isms; compile the
  # Linux (libusb-0.1) backend directly instead.
  buildPhase = ''
    runHook preBuild
    $CC -O3 -DVERSION_MAIN=1 -DVERSION_SUB=6 \
      main.c hex.c usb-libusb.c -lusb -o mphidflash
    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall
    install -Dm755 mphidflash $out/bin/mphidflash
    runHook postInstall
  '';

  meta = {
    description = "Command-line Microchip USB HID bootloader flasher";
    homepage = "https://github.com/AdamLaurie/mphidflash";
    license = lib.licenses.bsd3;
    platforms = lib.platforms.linux;
    mainProgram = "mphidflash";
  };
}
