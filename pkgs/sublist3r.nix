# Sublist3r: subdomain enumeration tool. Not in nixpkgs; pure-Python source build.
{ lib, python3Packages, fetchFromGitHub }:

python3Packages.buildPythonApplication {
  pname = "sublist3r";
  version = "1.1";
  pyproject = true;

  src = fetchFromGitHub {
    owner = "aboul3la";
    repo = "Sublist3r";
    rev = "729d649ec5370730172bf6f5314aafd68c874124";
    hash = "sha256-nrnb3jAIHw6WXR7VLNmi1YdfMBzHEIiMlGSbrvEi6Uc=";
  };

  build-system = [ python3Packages.setuptools ];
  dependencies = with python3Packages; [ requests dnspython ];
  pythonRelaxDeps = true;
  dontCheckRuntimeDeps = true;
  doCheck = false;

  meta = {
    description = "Fast subdomain enumeration tool for penetration testers";
    homepage = "https://github.com/aboul3la/Sublist3r";
    license = lib.licenses.gpl2Plus;
    mainProgram = "sublist3r";
  };
}
