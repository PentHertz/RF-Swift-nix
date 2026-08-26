# ChameleonUltra host CLI (RfidResearchGroup): the Python client that drives the
# Chameleon Ultra/Lite RFID emulator over serial. The optional C key-recovery
# helpers (software/src) are not built here because their CMake FetchContent-pulls
# xz from the network, which the sandbox blocks; the CLI's card read/write/emulate
# features work without them.
{ lib, python3Packages, fetchFromGitHub, makeWrapper }:

let
  pick = names: lib.filter (x: x != null) (map (n: python3Packages.${n} or null) names);
in
python3Packages.buildPythonApplication {
  pname = "chameleon-ultra-cli";
  version = "2-unstable";
  format = "other";

  src = fetchFromGitHub {
    owner = "RfidResearchGroup";
    repo = "ChameleonUltra";
    rev = "main";
    hash = "sha256-wUkw6uM+XPRgODRElJmSZM3AbD0X2balRgEVrn5V6V8=";
  };

  nativeBuildInputs = [ makeWrapper ];
  propagatedBuildInputs = pick [ "pyserial" "colorama" "prompt-toolkit" ];
  dontBuild = true;
  doCheck = false;

  installPhase = ''
    runHook preInstall
    mkdir -p $out/share/chameleon-ultra $out/bin
    cp -r software/script/* $out/share/chameleon-ultra/
    makeWrapper ${python3Packages.python.interpreter} $out/bin/chameleon_cli \
      --add-flags "$out/share/chameleon-ultra/chameleon_cli_main.py" \
      --chdir "$out/share/chameleon-ultra" \
      --prefix PYTHONPATH : "$out/share/chameleon-ultra:$PYTHONPATH"
    runHook postInstall
  '';

  meta = {
    description = "ChameleonUltra host CLI client (RFID emulator control)";
    homepage = "https://github.com/RfidResearchGroup/ChameleonUltra";
    license = lib.licenses.agpl3Only;
    mainProgram = "chameleon_cli";
  };
}
