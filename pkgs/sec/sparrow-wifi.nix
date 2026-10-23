{ lib, python3Packages, fetchFromGitHub, makeWrapper }:
let pick = names: lib.filter (x: x != null) (map (n: python3Packages.${n} or null) names);
in python3Packages.buildPythonApplication {
  pname = "sparrow-wifi"; version = "unstable-2026-10-21"; format = "other";
  src = fetchFromGitHub { owner = "ghostop14"; repo = "sparrow-wifi"; rev = "b4f4592714791d74caf15ea4723f4daf815c1efa"; hash = "sha256-nBVcRaFc0QQZOPMyG7aHdDMizHUEjbuFg/9sK28AIoQ="; };
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
