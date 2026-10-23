# sippts: toolset to audit VoIP/SIP servers (Pepelux).
{ lib, python3Packages, fetchFromGitHub }:

let
  pick = names: lib.filter (x: x != null) (map (n: python3Packages.${n} or null) names);
in
python3Packages.buildPythonApplication {
  pname = "sippts";
  version = "4-unstable-2026-09-14";
  pyproject = true;

  src = fetchFromGitHub {
    owner = "Pepelux";
    repo = "sippts";
    rev = "44568c86cff5d04ea363e787cdb0d2bffde9aa32";
    hash = "sha256-XZW/bCKvZ4gUr+CF87IDopk7BbTNnqlYMsjP6IPCZH8=";
  };

  build-system = [ python3Packages.setuptools ];
  propagatedBuildInputs = pick [
    "scapy" "requests" "ipaddress" "pyyaml" "websocket-client" "python-dateutil"
    "netifaces" "ipy" "pyshark" "rel"
  ];
  doCheck = false;
  # requirements.txt lists `resource`, which is a Unix stdlib module (no PyPI
  # dist), so the runtime-deps check can never satisfy it.
  dontCheckRuntimeDeps = true;
  pythonImportsCheck = [ ];

  meta = {
    description = "Set of tools to audit SIP-based VoIP systems";
    homepage = "https://github.com/Pepelux/sippts";
    license = lib.licenses.gpl3Plus;
    mainProgram = "sippts";
  };
}
