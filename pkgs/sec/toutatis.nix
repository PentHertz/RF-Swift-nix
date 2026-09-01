{ lib, python3Packages, fetchFromGitHub }:
let pick = names: lib.filter (x: x != null) (map (n: python3Packages.${n} or null) names);
in python3Packages.buildPythonApplication {
  pname = "toutatis"; version = "unstable"; pyproject = true;
  src = fetchFromGitHub { owner = "megadose"; repo = "toutatis"; rev = "d99967155e59966a560877148273ca0ff9f28508"; hash = "sha256-VY3g3LNfeQtCuQfM4Ky1akJ7YgLrNM9RnuC1M8eOw4c="; };
  build-system = pick [ "setuptools" ];
  dependencies = pick [ "requests" "beautifulsoup4" "trio" ];
  pythonRelaxDeps = true; dontCheckRuntimeDeps = true; doCheck = false;
  meta = { description = "Collect information about Instagram accounts via email/phone"; homepage = "https://github.com/megadose/toutatis"; license = lib.licenses.gpl3Plus; mainProgram = "toutatis"; };
}
