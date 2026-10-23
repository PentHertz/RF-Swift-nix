# CRCpp: header-only C++ CRC library (d-bahr). Not in nixpkgs; gr-droneid
# includes CRC.h from it. Installs the single header.
{ lib, stdenvNoCC, fetchFromGitHub }:

stdenvNoCC.mkDerivation {
  pname = "crcpp";
  version = "unstable-2026-10-15";

  src = fetchFromGitHub {
    owner = "d-bahr";
    repo = "CRCpp";
    rev = "77c690a9ea8e7bd0c64104786f26372a66c0eeb1";
    hash = "sha256-ACvwHaR/m3Cja8pDXpSd6KX9C8rW5rogTuYkdtZn9I8=";
  };

  # Header-only: expose inc/ (which contains CRC.h) as the include dir.
  installPhase = ''
    runHook preInstall
    mkdir -p $out/include
    cp inc/CRC.h $out/include/
    runHook postInstall
  '';

  meta = {
    description = "Header-only C++ CRC library";
    homepage = "https://github.com/d-bahr/CRCpp";
    license = lib.licenses.bsd3;
    platforms = lib.platforms.all;
  };
}
