# SSLyze: fast, deep TLS/SSL configuration scanner. Its native TLS engine,
# `nassl`, statically bundles two OpenSSL builds (a modern one and a legacy one
# with SSLv2/SSLv3 and weak ciphers) - a from-source compile that is heavy and
# fiddly. Upstream ships `nassl` as a prebuilt manylinux wheel, so use that and
# build sslyze itself (pure python) against it.
#
# Built against python312: nassl publishes cp312 wheels, and sslyze is a
# self-contained CLI so the interpreter pin is invisible to the rest of the env.
{ lib, stdenv, fetchurl, python312, autoPatchelfHook }:

let
  py = python312;
  pyp = py.pkgs;

  nassl = pyp.buildPythonPackage {
    pname = "nassl";
    version = "5.4.0";
    format = "wheel";
    src = fetchurl {
      url = "https://files.pythonhosted.org/packages/79/1f/b5c965907469683eaf1212e753982e42efba635b3e32e084fde75213d56a/nassl-5.4.0-cp312-cp312-manylinux2014_x86_64.manylinux_2_17_x86_64.whl";
      hash = "sha256-jEoawrzvaTVz8QABMROwpQQcCkusJofvzhZu7yUmr/s=";
    };
    nativeBuildInputs = [ autoPatchelfHook ];
    buildInputs = [ stdenv.cc.cc.lib ];
    # OpenSSL is statically linked into the wheel's .so; no runtime propagation.
    doCheck = false;
  };
in
pyp.buildPythonApplication {
  pname = "sslyze";
  version = "6.3.1";
  format = "setuptools";

  src = fetchurl {
    url = "https://files.pythonhosted.org/packages/15/07/8f5c92c149bfe9cb31619eb46d8ab055be670c6c16c740122afd6b496150/sslyze-6.3.1.tar.gz";
    hash = "sha256-LNQGL4Kj+mBdvTTjtx+Zlh5OfPQ4h52hxS9hmFX/vB0=";
  };

  dependencies = [ nassl pyp.cryptography pyp.tls-parser pyp.pydantic ];

  # sslyze pins cryptography<47; nixpkgs ships a newer one that works fine.
  pythonRelaxDeps = [ "cryptography" ];
  dontCheckRuntimeDeps = true;
  doCheck = false;

  meta = {
    description = "Fast and powerful SSL/TLS server scanning library and CLI";
    homepage = "https://github.com/nabla-c0d3/sslyze";
    license = lib.licenses.agpl3Only;
    mainProgram = "sslyze";
  };
}
