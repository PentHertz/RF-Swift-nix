# CommPy (scikit-commpy): digital communication algorithms in Python
# (modulation, channel coding, filters). Not in nixpkgs; gr-gfdm's Python
# helpers (gfdm.pygfdm), which its receiver hierarchical blocks and example
# flowgraphs import, need it.
{ lib, python3Packages }:

python3Packages.buildPythonPackage rec {
  pname = "scikit-commpy";
  version = "0.8.0";
  pyproject = true;

  src = python3Packages.fetchPypi {
    inherit pname version;
    hash = "sha256-aXFOdFosBoga94aTOxkRbPaaVTPy5nqPTwutTmyQeDQ=";
  };

  build-system = [ python3Packages.setuptools ];
  dependencies = with python3Packages; [ numpy scipy matplotlib sympy ];

  # setup.py also installs `runner`, a leftover template script (it imports a
  # nonexistent `package.module`).
  postInstall = ''
    rm -f $out/bin/runner
    rmdir --ignore-fail-on-non-empty $out/bin 2>/dev/null || true
  '';

  doCheck = false;
  pythonImportsCheck = [ "commpy" "commpy.filters" "commpy.modulation" ];

  meta = {
    description = "Digital communication algorithms in Python";
    homepage = "https://github.com/veeresht/CommPy";
    license = lib.licenses.bsd3;
    platforms = lib.platforms.unix;
  };
}
