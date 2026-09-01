# CaringCaribou: a listening/attack tool for the CAN bus (automotive).
{ lib, python3Packages, fetchFromGitHub }:

python3Packages.buildPythonApplication {
  pname = "caringcaribou";
  version = "0.5-unstable";
  pyproject = true;

  src = fetchFromGitHub {
    owner = "CaringCaribou";
    repo = "caringcaribou";
    rev = "092eff3c2c95bb7952a2a92ac12b6c1c29035b70";
    hash = "sha256-/em25rCDldixZq3LtDah981VjPGLfy+7MdzU/M/zvik=";
  };

  build-system = [ python3Packages.setuptools ];
  propagatedBuildInputs = with python3Packages; [ python-can ];
  # Upstream ships hardware-in-the-loop tests only.
  doCheck = false;
  pythonImportsCheck = [ "caringcaribou" ];

  meta = {
    description = "Listener and attack tool for the CAN bus (automotive security)";
    homepage = "https://github.com/CaringCaribou/caringcaribou";
    license = lib.licenses.gpl3Only;
    mainProgram = "caringcaribou";
  };
}
