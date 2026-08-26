# CRCpp: header-only C++ CRC library (d-bahr). Not in nixpkgs; gr-droneid
# includes CRC.h from it. Installs the single header.
{ lib, stdenvNoCC, fetchFromGitHub }:

stdenvNoCC.mkDerivation {
  pname = "crcpp";
  version = "unstable";

  src = fetchFromGitHub {
    owner = "d-bahr";
    repo = "CRCpp";
    rev = "0a0c7a8997cc82eb7a818e3286efe30c52d65be9";
    hash = "sha256-4tIgsPujSw7/4LtnzxLr2qFoPMlZCkpQqBLalqfoatI=";
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
