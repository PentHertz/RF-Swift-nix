# SCAT: Signalling Collection And Analysis Tool for cellular baseband diagnostics.
{ lib, python3Packages, fetchFromGitHub }:

python3Packages.buildPythonApplication {
  pname = "scat";
  version = "2.0.0";
  pyproject = true;

  src = fetchFromGitHub {
    owner = "fgsect";
    repo = "scat";
    rev = "master";
    hash = "sha256-CtBITIOpA1RYVGoIixTg6yNj0ofGmUX1iMrlYWN5H/Q=";
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
