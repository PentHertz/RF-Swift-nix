# WhisperPair: PoC for CVE-2025-36911 (Google Fast Pair) by PentHertz.
{ lib, stdenv, fetchFromGitHub, makeWrapper, python3, bluez }:

let
  pyEnv = python3.withPackages (ps: with ps; [ bleak cryptography ]);
in
stdenv.mkDerivation {
  pname = "whisperpair";
  version = "unstable";

  src = fetchFromGitHub {
    owner = "PentHertz";
    repo = "CVE-2025-36911-exploit";
    rev = "main";
    hash = "sha256-6RVTi66ZPBccbheC4KAQqgZs3kJVbrVV/Jk+Xd1FbXk=";
  };

  nativeBuildInputs = [ makeWrapper ];
  dontBuild = true;

  installPhase = ''
    runHook preInstall
    mkdir -p $out/share/whisperpair $out/bin
    cp -r . $out/share/whisperpair/
    makeWrapper ${pyEnv}/bin/python3 $out/bin/whisperpair \
      --add-flags "$out/share/whisperpair/whisperpair-cli.py" \
      --chdir "$out/share/whisperpair" \
      --prefix PATH : "${lib.makeBinPath [ bluez ]}" \
      --prefix PYTHONPATH : "$out/share/whisperpair"
    runHook postInstall
  '';

  meta = {
    description = "PoC exploit for CVE-2025-36911 (Google Fast Pair / WhisperPair)";
    homepage = "https://github.com/PentHertz/CVE-2025-36911-exploit";
    license = lib.licenses.mit;
    platforms = lib.platforms.linux;
    mainProgram = "whisperpair";
  };
}
