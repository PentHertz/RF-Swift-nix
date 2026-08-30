# WireTapper (h9zdev/WireTapper): a small Flask app run from its checkout
# (pip install -r WireTapper.txt -> Flask, requests). Matches RF-Swift-images'
# wiretapper_soft_install_fromsource. Wrapped with a Python that carries its two
# dependencies; the app files are shipped under share/.
{ lib, stdenv, fetchFromGitHub, makeWrapper, python3 }:

let
  pyEnv = python3.withPackages (ps: with ps; [ flask requests ]);
in
stdenv.mkDerivation {
  pname = "wiretapper";
  version = "unstable-2026-08-30";

  src = fetchFromGitHub {
    owner = "h9zdev";
    repo = "WireTapper";
    rev = "7e43d6a2ed06faf19e130f7dfabe0ab87638b909";
    hash = "sha256-gz4hFxLIObxiJ3OPFfpvXQfqcVhvlHa8L/AmNVXWnoY=";
  };

  nativeBuildInputs = [ makeWrapper ];
  dontBuild = true;

  installPhase = ''
    runHook preInstall
    mkdir -p $out/share/wiretapper $out/bin
    cp -r . $out/share/wiretapper/
    makeWrapper ${pyEnv}/bin/python3 $out/bin/wiretapper \
      --add-flags "$out/share/wiretapper/app.py" \
      --chdir "$out/share/wiretapper"
    runHook postInstall
  '';

  meta = {
    description = "WireTapper Flask web app (packet/traffic capture front-end)";
    homepage = "https://github.com/h9zdev/WireTapper";
    license = lib.licenses.mit;
    platforms = lib.platforms.linux;
    mainProgram = "wiretapper";
  };
}
