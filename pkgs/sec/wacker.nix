{ lib, python3Packages, fetchFromGitHub, makeWrapper }:
python3Packages.buildPythonApplication {
  pname = "wacker"; version = "unstable"; format = "other";
  src = fetchFromGitHub { owner = "blunderbuss-wctf"; repo = "wacker"; rev = "master"; hash = "sha256-upSloZykyoTOkrijcVkWnG6/LJYnVfwke1+H6Eh4D0I="; };
  nativeBuildInputs = [ makeWrapper ];
  dontCheckRuntimeDeps = true; doCheck = false;
  installPhase = ''
    runHook preInstall
    mkdir -p $out/share/wacker $out/bin
    cp -r . $out/share/wacker/
    makeWrapper ${python3Packages.python.interpreter} $out/bin/wacker \
      --add-flags "$out/share/wacker/wacker.py" --prefix PYTHONPATH : "$out/share/wacker:$PYTHONPATH"
    runHook postInstall
  '';
  meta = { description = "WPA3 SAE / Dragonblood password cracker over hostapd"; homepage = "https://github.com/blunderbuss-wctf/wacker"; license = lib.licenses.mit; mainProgram = "wacker"; };
}
