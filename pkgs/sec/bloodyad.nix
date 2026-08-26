{ lib, python3Packages, fetchFromGitHub }:
let pick = names: lib.filter (x: x != null) (map (n: python3Packages.${n} or null) names);
in python3Packages.buildPythonApplication {
  pname = "bloodyad"; version = "unstable"; pyproject = true;
  src = fetchFromGitHub { owner = "CravateRouge"; repo = "bloodyAD"; rev = "main"; hash = "sha256-J4vQX8z6mqSkwnonNOVYJZGyA63p5QdIkRAiiSld6yg="; };
  build-system = pick [ "hatchling" ];
  dependencies = pick [ "impacket" "ldap3" "gssapi" "dnspython" "pyasn1" "cryptography" "asn1crypto" "minikerberos" "winacl" ];
  pythonRelaxDeps = true; dontCheckRuntimeDeps = true; doCheck = false;
  meta = { description = "AD privilege escalation swiss army knife"; homepage = "https://github.com/CravateRouge/bloodyAD"; license = lib.licenses.mit; mainProgram = "bloodyAD"; };
}
