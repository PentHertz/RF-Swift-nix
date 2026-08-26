{ lib, python3Packages, fetchFromGitHub, makeWrapper }:
let pick = names: lib.filter (x: x != null) (map (n: python3Packages.${n} or null) names);
in python3Packages.buildPythonApplication {
  pname = "sniffle"; version = "unstable"; format = "other";
  src = fetchFromGitHub { owner = "nccgroup"; repo = "Sniffle"; rev = "master"; hash = "sha256-i9A+BrO6cz6nPI0Z/yTp9ehuztbhBUmZ5NakvcXQ+0I="; };
  nativeBuildInputs = [ makeWrapper ];
  propagatedBuildInputs = pick [ "pyserial" ];
  dontCheckRuntimeDeps = true; doCheck = false;
  installPhase = ''
    runHook preInstall
    mkdir -p $out/share/sniffle $out/bin
    cp -r python_cli/* $out/share/sniffle/ 2>/dev/null || cp -r . $out/share/sniffle/
    for s in sniff_receiver scanner; do
      [ -f "$out/share/sniffle/$s.py" ] && makeWrapper ${python3Packages.python.interpreter} $out/bin/sniffle-$s \
        --add-flags "$out/share/sniffle/$s.py" --prefix PYTHONPATH : "$out/share/sniffle:$PYTHONPATH" || true
    done
    runHook postInstall
  '';
  meta = { description = "Sniffle: a BLE sniffer for TI CC1352/CC26x2"; homepage = "https://github.com/nccgroup/Sniffle"; license = lib.licenses.gpl3Plus; };
}
