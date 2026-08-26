# SSTImap: server-side template injection / code-injection scanner.
{ lib, python3Packages, fetchFromGitHub, makeWrapper }:

let
  pick = names: lib.filter (x: x != null) (map (n: python3Packages.${n} or null) names);
in
python3Packages.buildPythonApplication {
  pname = "sstimap";
  version = "1.2.1-unstable";
  format = "other";

  src = fetchFromGitHub {
    owner = "vladko312";
    repo = "SSTImap";
    rev = "master";
    hash = "sha256-G5oUyy0bQ2k6/veL/YwlNIKB5xUY+bRtL3RwuPhKJZg=";
  };

  nativeBuildInputs = [ makeWrapper ];
  propagatedBuildInputs = pick [ "requests" "chardet" "urllib3" "pysocks" ];
  dontBuild = true;
  doCheck = false;

  installPhase = ''
    runHook preInstall
    mkdir -p $out/share/sstimap $out/bin
    cp -r . $out/share/sstimap/
    makeWrapper ${python3Packages.python.interpreter} $out/bin/sstimap \
      --add-flags "$out/share/sstimap/sstimap.py" \
      --chdir "$out/share/sstimap" \
      --prefix PYTHONPATH : "$out/share/sstimap:$PYTHONPATH"
    runHook postInstall
  '';

  meta = {
    description = "Server-Side Template Injection and Code Injection detection/exploitation tool";
    homepage = "https://github.com/vladko312/SSTImap";
    license = lib.licenses.gpl3Plus;
    mainProgram = "sstimap";
  };
}
