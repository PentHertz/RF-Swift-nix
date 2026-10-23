# reFlutter (Impact-I/reFlutter): repacks Flutter APK/IPA files with a patched
# libflutter engine (traffic interception, Dart snapshot dump). Matches
# RF-Swift-images' reflutter_soft_install (pipx install reflutter). Pure
# stdlib; the engine hash tables and patched engines are fetched from GitHub at
# run time, exactly like the pipx install.
{ lib, python3Packages, fetchFromGitHub }:

python3Packages.buildPythonApplication {
  pname = "reflutter";
  version = "0.9.8-unstable-2026-10-15";
  pyproject = true;

  src = fetchFromGitHub {
    owner = "Impact-I";
    repo = "reFlutter";
    rev = "846a00033ef39a53502eed8b775b6699fe0fc684"; # one commit past "0.9.8" (PyPI 0.9.8); no git tags
    hash = "sha256-uVP7AV7F28NJoPKtUIBYkKlUvo5X+pEyRfgp16tcaCQ=";
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
