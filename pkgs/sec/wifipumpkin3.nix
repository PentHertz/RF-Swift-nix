{ lib, python3Packages, fetchFromGitHub }:
let pick = names: lib.filter (x: x != null) (map (n: python3Packages.${n} or null) names);
in python3Packages.buildPythonApplication {
  pname = "wifipumpkin3"; version = "unstable"; pyproject = true;
  src = fetchFromGitHub { owner = "P0cL4bs"; repo = "wifipumpkin3"; rev = "344a47588f622730bc38b498b915e584cef4a19b"; hash = "sha256-WTEgX/L+qJu+LOQlwIOse2c8CRyQBam6YnLZOxVYhPE="; };
  build-system = pick [ "setuptools" ];
  dependencies = pick [ "pyqt5" "tornado" "netfilterqueue" "scapy" "requests" "pyroute2" "netaddr" "psutil" ];
  # Upstream setup.py creates ~/.config/wifipumpkin3 while querying build
  # requirements. Keep that unavoidable setup-time side effect in the sandbox.
  preBuild = ''
    export HOME="$TMPDIR"
  '';
  pythonRelaxDeps = true; dontCheckRuntimeDeps = true; doCheck = false;
  meta = { description = "Rogue AP framework for red-team / MITM"; homepage = "https://github.com/P0cL4bs/wifipumpkin3"; license = lib.licenses.asl20; mainProgram = "wifipumpkin3"; };
}
