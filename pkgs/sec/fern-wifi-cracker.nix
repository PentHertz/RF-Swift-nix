# Fern Wifi Cracker: a Qt GUI over the aircrack-ng suite and reaver for WEP/WPA/WPS
# auditing (savio-code). Not pip-installable; ship the app dir and wrap execute.py.
{ lib, stdenv, fetchFromGitHub, makeWrapper, python3
, aircrack-ng, reaver, macchanger, xterm, iw, iproute2 }:

let
  pyEnv = python3.withPackages (ps: with ps; [ pyqt5 scapy ]);
in
stdenv.mkDerivation {
  pname = "fern-wifi-cracker";
  version = "3.0-unstable";

  src = fetchFromGitHub {
    owner = "savio-code";
    repo = "fern-wifi-cracker";
    rev = "58ed54ef8294e4019a3f5056f1e3424ce033f3cd";
    hash = "sha256-wR6cCiwQ+HPDqJmTqS1k1NUT219ewYHzNDCMegmU0KE=";
  };

  nativeBuildInputs = [ makeWrapper ];
  dontBuild = true;

  installPhase = ''
    runHook preInstall
    mkdir -p $out/share/fern-wifi-cracker $out/bin
    cp -r Fern-Wifi-Cracker/* $out/share/fern-wifi-cracker/
    makeWrapper ${pyEnv}/bin/python3 $out/bin/fern-wifi-cracker \
      --add-flags "$out/share/fern-wifi-cracker/execute.py" \
      --chdir "$out/share/fern-wifi-cracker" \
      --prefix PATH : "${lib.makeBinPath [ aircrack-ng reaver macchanger xterm iw iproute2 ]}"
    runHook postInstall
  '';

  meta = {
    description = "Qt GUI for WEP/WPA/WPS wireless auditing (aircrack-ng + reaver front-end)";
    homepage = "https://github.com/savio-code/fern-wifi-cracker";
    license = lib.licenses.gpl3Plus;
    platforms = lib.platforms.linux;
    mainProgram = "fern-wifi-cracker";
  };
}
