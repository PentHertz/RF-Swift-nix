# bromelia: Python Diameter (RFC 6733) protocol stack - the base the telecom
# image's pyhss/bromelia steps pip-install (both install exactly this package).
# Pure Python from PyPI; only depends on PyYAML.
{ lib, python3Packages, fetchPypi }:

python3Packages.buildPythonPackage rec {
  pname = "bromelia";
  version = "0.3.1";
  pyproject = true;

  src = fetchPypi {
    inherit pname version;
    hash = "sha256-89I6TCxzA/+sHeXVByz165riZSEA+OpEMzj/xtvNFcw=";
  };

  build-system = [ python3Packages.setuptools ];
  dependencies = [ python3Packages.pyyaml ];

  # Upstream tests need a live Diameter peer.
  doCheck = false;
  pythonImportsCheck = [ "bromelia" ];

  meta = {
    description = "Python Diameter protocol stack (3GPP/IMS/EPC interfaces)";
    homepage = "https://github.com/heimiricmr/bromelia";
    license = lib.licenses.mit;
    platforms = lib.platforms.unix;
  };
}
