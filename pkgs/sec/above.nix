# above (caster0x00/above): an "invisible network protocol sniffer" for
# discovering L2/L3 attack surface. Python app (scapy + colorama). Matches
# RF-Swift-images' above_soft_install (pipx install from git).
{ lib, python3Packages, fetchFromGitHub }:

python3Packages.buildPythonApplication {
  pname = "above";
  version = "unstable-2026-08-30";
  pyproject = true;

  src = fetchFromGitHub {
    owner = "caster0x00";
    repo = "above";
    rev = "313f550ebb87d815aeece6792104b8c3f2a9db8f";
    hash = "sha256-wyXWGfthzJeHZoJe4OKe9k2BIwLae/aOUtiJpT4SfHw=";
  };

  build-system = [ python3Packages.setuptools ];
  dependencies = with python3Packages; [ scapy colorama ];
  pythonImportsCheck = [ "above" ];

  meta = {
    description = "Invisible network protocol sniffer for L2/L3 attack-surface discovery";
    homepage = "https://github.com/caster0x00/above";
    license = lib.licenses.gpl3Only;
    platforms = lib.platforms.linux;
    mainProgram = "above";
  };
}
