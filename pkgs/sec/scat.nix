# SCAT: Signalling Collection And Analysis Tool for cellular baseband diagnostics.
{ lib, python3Packages, fetchFromGitHub }:

python3Packages.buildPythonApplication {
  pname = "scat";
  version = "2.0.0-unstable-2026-08-26";
  pyproject = true;

  src = fetchFromGitHub {
    owner = "fgsect";
    repo = "scat";
    rev = "fc2a53699373148d1eb97617c0d58e9e2255f61a";
    hash = "sha256-EMjYbBQIgKGmOBFXZOOuTtTRCGQmnWdI1JAd47zIQSg=";
  };

  build-system = [ python3Packages.hatchling ];
  propagatedBuildInputs = with python3Packages; [ pyusb pyserial bitstring ];
  doCheck = false;

  meta = {
    description = "Signalling Collection And Analysis Tool for Qualcomm/Samsung baseband diagnostics";
    homepage = "https://github.com/fgsect/scat";
    license = lib.licenses.gpl2Plus;
    mainProgram = "scat";
  };
}
