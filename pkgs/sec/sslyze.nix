# SSLyze: fast, deep TLS/SSL configuration scanner. Its native TLS engine,
# `nassl`, statically bundles two OpenSSL builds (a modern one and a legacy one
# with SSLv2/SSLv3 and weak ciphers) - a from-source compile that is heavy and
# fiddly. Upstream ships `nassl` as prebuilt wheels, so use the wheel matching
# the host and build sslyze itself (pure python) against it.
#
# Built against python312: nassl publishes cp312 wheels, and sslyze is a
# self-contained CLI so the interpreter pin is invisible to the rest of the env.
{ lib, stdenv, fetchurl, python312, autoPatchelfHook }:

let
  py = python312;
  pyp = py.pkgs;

  # nassl ships a statically-linked OpenSSL inside a per-platform binary wheel.
  # Select the wheel for the host so sslyze works on Linux (x86_64/aarch64) and
  # macOS arm64 alike, rather than forcing the x86_64 Linux wheel everywhere
  # (which cannot be patchelf'd on other platforms and so silently drops sslyze
  # from the network environment there).
  nasslWheels = {
    x86_64-linux = {
      url = "https://files.pythonhosted.org/packages/79/1f/b5c965907469683eaf1212e753982e42efba635b3e32e084fde75213d56a/nassl-5.4.0-cp312-cp312-manylinux2014_x86_64.manylinux_2_17_x86_64.whl";
      hash = "sha256-jEoawrzvaTVz8QABMROwpQQcCkusJofvzhZu7yUmr/s=";
    };
    aarch64-linux = {
      url = "https://files.pythonhosted.org/packages/94/6b/dc69b6fa5bc5a20954bf9ae19420081805a2a037a01f1173bbbe2f7c49e6/nassl-5.4.0-cp312-cp312-manylinux2014_aarch64.manylinux_2_17_aarch64.whl";
      hash = "sha256-dtCuVAckfFhoEsVQ6gsRiSJGY8mfR+aRqRIE+sTfpeM=";
    };
    aarch64-darwin = {
      url = "https://files.pythonhosted.org/packages/e6/7c/da47030d518ffe7b293d3e64a07d869cc00c8a395baf8cd80593e1265876/nassl-5.4.0-cp312-cp312-macosx_11_0_arm64.whl";
      hash = "sha256-1GFlGbGMoTvf7GGALpy85XOLeihcdTB1Sxd63In8dWE=";
    };
  };
  nasslWheel = nasslWheels.${stdenv.hostPlatform.system}
    or (throw "sslyze/nassl: no prebuilt wheel for ${stdenv.hostPlatform.system}");

  nassl = pyp.buildPythonPackage {
    pname = "nassl";
    version = "5.4.0";
    format = "wheel";
    src = fetchurl nasslWheel;
    # The Linux wheels are ELF and need their interpreter/rpath fixed; the macOS
    # wheel is Mach-O and needs neither autoPatchelf nor libstdc++.
    nativeBuildInputs = lib.optionals stdenv.hostPlatform.isLinux [ autoPatchelfHook ];
    buildInputs = lib.optionals stdenv.hostPlatform.isLinux [ stdenv.cc.cc.lib ];
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
    platforms = builtins.attrNames nasslWheels;
    mainProgram = "sslyze";
  };
}
