# sippts: toolset to audit VoIP/SIP servers (Pepelux).
{ lib, python3Packages, fetchFromGitHub }:

let
  pick = names: lib.filter (x: x != null) (map (n: python3Packages.${n} or null) names);
in
python3Packages.buildPythonApplication {
  pname = "sippts";
  version = "4-unstable";
  pyproject = true;

  src = fetchFromGitHub {
    owner = "Pepelux";
    repo = "sippts";
    rev = "master";
    hash = "sha256-QAYhoeH/hEPaAPsyTD88NJjRko8IorgyFXudpp4zjZs=";
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
