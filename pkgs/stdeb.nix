# stdeb: Python-to-Debian source-package tooling. Not in the pinned py310 set,
# but pure Python, so we build it from PyPI. It is only a build dependency of
# bluing (whose setup requires it).
{ lib, buildPythonPackage, fetchPypi, setuptools }:

buildPythonPackage rec {
  pname = "stdeb";
  version = "0.10.0";
  pyproject = true;

  src = fetchPypi {
    inherit pname version;
    hash = "sha256-CMIsnAOyihQP4+xQZLU6UognnyLllsoGsL5pjVDJPPI=";
  };

  build-system = [ setuptools ];
  propagatedBuildInputs = [ setuptools ];

  doCheck = false;
  pythonImportsCheck = [ "stdeb" ];

  meta = {
    description = "Python to Debian source package conversion utility";
    homepage = "https://github.com/astraw/stdeb";
    license = lib.licenses.mit;
  };
}
