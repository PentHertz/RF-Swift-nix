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
  version = "unstable-2026-09-11";

  src = fetchFromGitHub {
    owner = "h9zdev";
    repo = "WireTapper";
    rev = "395bb9348f9c9458cb0b7994623c4c5ae937b544";
    hash = "sha256-wm7hNN2LMTkIbJ/RHT0sWpQsUdZITEkzVxcjRT+a+5w=";
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
