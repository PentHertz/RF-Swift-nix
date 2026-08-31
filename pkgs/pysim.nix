# pysim (Osmocom): program SIM/USIM/ISIM cards. Not in nixpkgs; Python source.
{ lib, python3Packages, fetchFromGitHub, pcsclite }:

let
  pick = names: lib.filter (x: x != null) (map (n: python3Packages.${n} or null) names);
in
python3Packages.buildPythonApplication {
  pname = "pysim";
  version = "0-unstable-2026-04-22";
  pyproject = true;

  # Pin an exact commit, never a branch name: fetchFromGitHub is a fixed-output
  # derivation, so `rev = "master"` breaks with a hash mismatch as soon as
  # upstream master moves (which is exactly what took the telecom cache build
  # down). Bump rev and hash together via `nix flake prefetch
  # github:osmocom/pysim/<rev>`.
  src = fetchFromGitHub {
    owner = "osmocom";
    repo = "pysim";
    rev = "d4717bd014901d41863ccd408a3ea538d6fc1fc6";
    hash = "sha256-NlF63uYSUFhNrkT0oV2P46cdlL5MAJ69CObpqJR/McI=";
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
