{ lib, python3Packages, fetchFromGitHub }:
let pick = names: lib.filter (x: x != null) (map (n: python3Packages.${n} or null) names);
in python3Packages.buildPythonApplication {
  pname = "autorecon"; version = "unstable"; pyproject = true;
  src = fetchFromGitHub { owner = "Tib3rius"; repo = "AutoRecon"; rev = "e7e98f60bdc5fb1695159c1bbcdfdf2746d30fa6"; hash = "sha256-xSRfsfLRYt7jS5Jpp6fz5/Kj2DiNI3hgUbUI9w3AHkw="; };
  build-system = pick [ "setuptools" "poetry-core" ];
  dependencies = pick [ "python-libnmap" "toml" "colorama" "impacket" "requests" "appdirs" ];
  pythonRelaxDeps = true; dontCheckRuntimeDeps = true; doCheck = false;
  meta = { description = "Multi-threaded network reconnaissance tool"; homepage = "https://github.com/Tib3rius/AutoRecon"; license = lib.licenses.gpl3Plus; mainProgram = "autorecon"; };
}
