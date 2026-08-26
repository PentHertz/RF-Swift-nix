{ lib, python3Packages, fetchFromGitHub }:
let pick = names: lib.filter (x: x != null) (map (n: python3Packages.${n} or null) names);
in python3Packages.buildPythonApplication {
  pname = "lsassy"; version = "unstable"; pyproject = true;
  src = fetchFromGitHub { owner = "login-securite"; repo = "lsassy"; rev = "master"; hash = "sha256-lPbZnoR6qWfVBSRAbTJsKpjBieidNsYgAXI3CXHEt1w="; };
  build-system = pick [ "poetry-core" ];
  dependencies = pick [ "impacket" "netaddr" "pypykatz" "rich" "dploot" ];
  pythonRelaxDeps = true; dontCheckRuntimeDeps = true; doCheck = false;
  meta = { description = "Remotely extract LSASS dumps"; homepage = "https://github.com/login-securite/lsassy"; license = lib.licenses.gpl3Plus; mainProgram = "lsassy"; };
}
