# reFlutter (Impact-I/reFlutter): repacks Flutter APK/IPA files with a patched
# libflutter engine (traffic interception, Dart snapshot dump). Matches
# RF-Swift-images' reflutter_soft_install (pipx install reflutter). Pure
# stdlib; the engine hash tables and patched engines are fetched from GitHub at
# run time, exactly like the pipx install.
{ lib, python3Packages, fetchFromGitHub }:

python3Packages.buildPythonApplication {
  pname = "reflutter";
  version = "0.9.8";
  pyproject = true;

  src = fetchFromGitHub {
    owner = "Impact-I";
    repo = "reFlutter";
    rev = "1b5d688ffc00896d3c466797913a99fc846e4d38"; # "0.9.8" (PyPI 0.9.8), no git tag
    hash = "sha256-AhdQaLIUoQU9bKr65F8CL5zeK3V9dm2rTNSpppy8mas=";
  };

  build-system = [ python3Packages.setuptools ];

  doCheck = false; # no test suite
  pythonImportsCheck = [ "reflutter" ];

  meta = {
    description = "Flutter reverse engineering framework (patched engine repacking for APK/IPA)";
    homepage = "https://github.com/Impact-I/reFlutter";
    license = lib.licenses.gpl3Plus;
    platforms = lib.platforms.unix;
    mainProgram = "reflutter";
  };
}
