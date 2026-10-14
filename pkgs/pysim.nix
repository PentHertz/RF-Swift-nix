# pysim (Osmocom): program SIM/USIM/ISIM cards. Not in nixpkgs; Python source.
{ lib, python3Packages, fetchFromGitHub, pcsclite }:

let
  pick = names: lib.filter (x: x != null) (map (n: python3Packages.${n} or null) names);
  # Osmocom's shared Python utilities (the `osmocom` module every pySim script
  # imports: TLV/construct helpers, utils). Not in nixpkgs.
  pyosmocom = python3Packages.buildPythonPackage rec {
    pname = "pyosmocom";
    version = "0.0.12";
    pyproject = true;
    src = python3Packages.fetchPypi {
      inherit pname version;
      hash = "sha256-EMOnrmuEye9yq1xx7sQ19fLzyS7zn6vGabZh7ZcrL/8=";
    };
    build-system = [ python3Packages.setuptools ];
    dependencies = with python3Packages; [ gsm0338 construct ];
    doCheck = false;
    pythonImportsCheck = [ "osmocom" "osmocom.utils" "osmocom.tlv" ];
    meta.license = lib.licenses.gpl2Plus;
  };
  # SMPP client/server on Twisted, for pySim-smpp2sim.py (SMPP-to-SIM bridge).
  # It pins Twisted~=23.10 and smpp.pdu3, the PyPI name of the same `smpp.pdu`
  # module nixpkgs' smpp-pdu provides; both share the `smpp` package through a
  # pkgutil-style namespace, so they combine. Relax the Twisted pin.
  smpp-twisted3 = python3Packages.buildPythonPackage rec {
    pname = "smpp.twisted3";
    version = "0.8";
    pyproject = true;
    src = python3Packages.fetchPypi {
      inherit pname version;
      hash = "sha256-8XLxw36jZT2y/tJYmQsn+UwvT4iXcVrvXC4Eycsb7FY=";
    };
    build-system = [ python3Packages.setuptools ];
    dependencies = with python3Packages; [ twisted smpp-pdu pyopenssl ];
    pythonRelaxDeps = [ "twisted" ];
    pythonRemoveDeps = [ "smpp.pdu3" ];
    doCheck = false;
    pythonImportsCheck = [ "smpp.twisted.protocol" ];
    meta.license = lib.licenses.asl20;
  };
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
    # setup.py's install_requires; dontCheckRuntimeDeps below hid these.
    "pycryptodomex"
    "cryptography"
    "asn1tools"
    "smpplib"
    # Imported by pySim-trace.py (drives tshark) but not declared upstream.
    "pyshark"
    # Twisted's TLS verification, imported by pySim-smpp2sim.py (setup.py
    # lists it under the smdpp extra).
    "service-identity"
  ] ++ [ pyosmocom smpp-twisted3 ];
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
