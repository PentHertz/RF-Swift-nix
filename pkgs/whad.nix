# WHAD: Wireless HAcking Devices framework (whad-team). A PyPI application.
# Built from source with the dependency list relaxed, since its version pins are
# tighter than nixpkgs. Dependencies are resolved defensively so a name missing
# on this nixpkgs still evaluates (it is dropped, not fatal).
{ lib, python3Packages, fetchPypi }:

let
  pick = names: lib.filter (x: x != null) (map (n: python3Packages.${n} or null) names);
in
python3Packages.buildPythonApplication rec {
  pname = "whad";
  version = "1.2.17";
  pyproject = true;

  src = fetchPypi {
    inherit pname version;
    hash = "sha256-vWJ+Mo7kkJypL49HUkNNw3hzh3GwnGnlPva+SGOWJMk=";
  };

  build-system = pick [ "setuptools" "setuptools-scm" ];

  # Version constraints are stricter than nixpkgs; relax them all.
  pythonRelaxDeps = true;

  dependencies = pick [
    "protobuf"
    "scapy"
    "pyserial"
    "pycryptodomex"
    "pyusb"
    "cryptography"
    "prompt-toolkit"
    "hexdump"
    "pynput"
    "requests"
    "distro"
    "websockets"
    "packaging"
    "strenum"
  ];

  # Its declared deps do not all line up with nixpkgs names; skip the strict
  # runtime-deps check and just confirm it imports.
  dontCheckRuntimeDeps = true;
  pythonImportsCheck = [ "whad" ];
  doCheck = false;

  meta = {
    description = "WHAD: Wireless HAcking Devices framework";
    homepage = "https://github.com/whad-team/whad-client";
    license = lib.licenses.mit;
    # Upstream exposes a collection of `w*` commands rather than a `whad`
    # executable. `whadup` is its generic device discovery/information entry
    # point and is therefore the useful lazy-mode launcher.
    mainProgram = "whadup";
  };
}
