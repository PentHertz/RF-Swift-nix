# HExHTTP (c0dejump/HExHTTP): tests HTTP headers to find cache-poisoning and
# other header-driven vulnerabilities. Matches RF-Swift-images'
# hexhttp_soft_install (pipx install . from git).
{ lib, python3Packages, fetchFromGitHub }:

python3Packages.buildPythonApplication {
  pname = "hexhttp";
  version = "2.5";
  pyproject = true;

  src = fetchFromGitHub {
    owner = "c0dejump";
    repo = "HExHTTP";
    rev = "a70345241f017f9b841c85472feae4237b4584cb";
    hash = "sha256-s2ZPL57Oz1Lt1JmJqlsmWzDWmws6/5NEduGkcftcTOU=";
  };

  # pyproject.toml only lists packages (packages.find), so the wheel misses the
  # top-level hexhttp.py and cli.py its own entry point imports
  # (`from hexhttp import cli_main`): declare them as py-modules.
  postPatch = ''
    printf '\n[tool.setuptools]\npy-modules = ["hexhttp", "cli"]\n' >> pyproject.toml
  '';

  build-system = [ python3Packages.setuptools ];
  dependencies = with python3Packages; [
    requests urllib3 beautifulsoup4 httpx tldextract curl-cffi
  ];
  pythonRelaxDeps = true;
  dontCheckRuntimeDeps = true;

  meta = {
    description = "HTTP-header vulnerability and cache-poisoning tester";
    homepage = "https://github.com/c0dejump/HExHTTP";
    license = lib.licenses.mit;
    platforms = lib.platforms.unix;
    mainProgram = "hexhttp";
  };
}
