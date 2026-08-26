# pysim (Osmocom): program SIM/USIM/ISIM cards. Not in nixpkgs; Python source.
{ lib, python3Packages, fetchFromGitHub, pcsclite }:

let
  pick = names: lib.filter (x: x != null) (map (n: python3Packages.${n} or null) names);
in
python3Packages.buildPythonApplication {
  pname = "pysim";
  version = "unstable";
  pyproject = true;

  src = fetchFromGitHub {
    owner = "osmocom";
    repo = "pysim";
    rev = "master";
    hash = "sha256-O4Lim+mVCdu6ETM3zZqEcOj23KTPmZanYJBi60oMQW8=";
  };

  build-system = pick [ "setuptools" ];
  pythonRelaxDeps = true;
  dependencies = pick [
    "pyscard"
    "pyserial"
    "jsonpath-ng"
    "colorlog"
    "termcolor"
    "cmd2"
    "packaging"
    "bidict"
    "gsm0338"
    "pytlv"
    "smpp-pdu"
    "construct"
    "pyyaml"
  ];
  buildInputs = [ pcsclite ];
  dontCheckRuntimeDeps = true;
  doCheck = false;

  meta = {
    description = "Osmocom SIM/USIM/ISIM card programming tools (pySim)";
    homepage = "https://github.com/osmocom/pysim";
    license = lib.licenses.gpl2Plus;
    mainProgram = "pySim-shell.py";
  };
}
