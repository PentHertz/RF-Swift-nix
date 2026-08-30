# Argus (argus-recon on PyPI): an all-in-one recon/network-info CLI. Matches
# RF-Swift-images' argus_soft_install (pipx install argus-recon).
{ lib, python3Packages, fetchPypi }:

python3Packages.buildPythonApplication rec {
  pname = "argus-recon";
  version = "2.0.0";
  pyproject = true;

  src = fetchPypi {
    pname = "argus_recon";
    inherit version;
    hash = "sha256-wM29aP/HOrTAsMtlTeEM4cSBUfzoLRtxv+3gUYuL6iQ=";
  };

  build-system = [ python3Packages.setuptools ];
  dependencies = with python3Packages; [
    requests urllib3 rich dnspython paramiko beautifulsoup4 lxml jinja2
    packaging python-slugify mmh3 idna
  ];
  # Upstream pins conservative upper bounds (rich<14, packaging<25); this pin
  # ships newer. Relax so it builds against them.
  pythonRelaxDeps = true;
  dontCheckRuntimeDeps = true;

  meta = {
    description = "All-in-one network reconnaissance and information-gathering CLI";
    homepage = "https://pypi.org/project/argus-recon/";
    license = lib.licenses.mit;
    platforms = lib.platforms.unix;
    mainProgram = "argus";
  };
}
