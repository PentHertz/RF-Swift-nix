{ lib, python3Packages, fetchFromGitHub, makeWrapper }:
let pick = names: lib.filter (x: x != null) (map (n: python3Packages.${n} or null) names);
in python3Packages.buildPythonApplication {
  pname = "sparrow-wifi"; version = "unstable"; format = "other";
  src = fetchFromGitHub { owner = "ghostop14"; repo = "sparrow-wifi"; rev = "7559b3880717c0c535abb7c23fa548cfb17b49dc"; hash = "sha256-oeDXfkdbIBHx1G+NYzHHLQ4ApAbQ+0uriC1xtb9PzYY="; };
  nativeBuildInputs = [ makeWrapper ];
  propagatedBuildInputs = pick [ "pyqt5" "gps3" "python-dateutil" "matplotlib" "manuf" "requests" ];
  dontCheckRuntimeDeps = true; doCheck = false;
  installPhase = ''
    runHook preInstall
    mkdir -p $out/share/sparrow-wifi $out/bin; cp -r . $out/share/sparrow-wifi/
    makeWrapper ${python3Packages.python.interpreter} $out/bin/sparrow-wifi \
      --add-flags "$out/share/sparrow-wifi/sparrow-wifi.py" --prefix PYTHONPATH : "$out/share/sparrow-wifi:$PYTHONPATH"
    runHook postInstall
  '';
  meta = { description = "GUI Wi-Fi/Bluetooth spectrum analyzer"; homepage = "https://github.com/ghostop14/sparrow-wifi"; license = lib.licenses.gpl3Plus; mainProgram = "sparrow-wifi"; };
}
