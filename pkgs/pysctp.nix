# pysctp: Python bindings for the Linux SCTP stack (a compiled _sctp C extension).
# Needed by telecom signaling tools (Diameter/SS7 over SCTP).
{ lib, python3Packages, fetchFromGitHub, lksctp-tools }:

python3Packages.buildPythonPackage {
  pname = "pysctp";
  version = "unstable";
  format = "setuptools";

  src = fetchFromGitHub {
    owner = "FlUxIuS";
    repo = "pysctp";
    rev = "d7484e885f8abc9fa30bdb7c3afa849ca49a5cd3";
    hash = "sha256-bl0iHZ8hed9FUyiTvg6cDrYVy5po+7b7lhXsn0kQirE=";
  };

  buildInputs = [ lksctp-tools ];
  doCheck = false;
  pythonImportsCheck = [ "sctp" ];

  meta = {
    description = "Python SCTP protocol bindings (_sctp)";
    homepage = "https://github.com/FlUxIuS/pysctp";
    license = lib.licenses.lgpl21Plus;
  };
}
