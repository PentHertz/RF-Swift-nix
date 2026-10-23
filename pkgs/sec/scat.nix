# SCAT: Signalling Collection And Analysis Tool for cellular baseband diagnostics.
{ lib, python3Packages, fetchFromGitHub }:

python3Packages.buildPythonApplication rec {
  pname = "scat";
  version = "2.1.2-unstable-2026-10-15";
  pyproject = true;

  src = fetchFromGitHub {
    owner = "fgsect";
    repo = "scat";
    rev = "646a764eb9fba4e2aa6ba0e847c1fd018853fc17";
    hash = "sha256-6FMjnUUoQvFlt5ZdfLZ8sZt577KqnMtQD7CM6Vbf1jQ=";
  };

  # hatch-vcs fills the source_archive URL with the git commit, and the
  # fetched tree has no .git: substitute the pinned rev instead.
  postPatch = ''
    substituteInPlace pyproject.toml --replace-fail '{commit_hash}' '${src.rev}'
  '';
  env.SETUPTOOLS_SCM_PRETEND_VERSION = "2.1.2";

  build-system = with python3Packages; [ hatchling hatch-vcs ];
  propagatedBuildInputs = with python3Packages; [ pyusb pyserial bitstring packaging ];
  doCheck = false;

  meta = {
    description = "Signalling Collection And Analysis Tool for Qualcomm/Samsung baseband diagnostics";
    homepage = "https://github.com/fgsect/scat";
    license = lib.licenses.gpl2Plus;
    mainProgram = "scat";
  };
}
