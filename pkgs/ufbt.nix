# uFBT (flipperdevices/flipperzero-ufbt): micro Flipper Build Tool for building
# and launching Flipper Zero apps (.fap). Matches the ufbt part of
# RF-Swift-images' flipper_zero_soft_install (pipx install ufbt).
# Built from the PyPI sdist: its PKG-INFO carries the version, so
# setuptools-git-versioning needs no .git. The package itself is offline; on
# first use ufbt downloads the Flipper SDK and the prebuilt ARM toolchain into
# $UFBT_HOME (default ~/.ufbt), as the pipx install does (on NixOS that
# generic-Linux toolchain may need nix-ld or an FHS env to run).
{ lib, python3Packages, fetchPypi }:

python3Packages.buildPythonApplication rec {
  pname = "ufbt";
  version = "0.2.6";
  pyproject = true;

  src = fetchPypi {
    inherit pname version;
    hash = "sha256-TxqFiFhZjtLiW7q2ni6mBLwAdYw7Ho7PiXophmFXNjs=";
  };

  # pyproject pins setuptools-git-versioning<2; nixpkgs ships 3.x, which reads
  # the same config and takes the version from the sdist's PKG-INFO.
  postPatch = ''
    substituteInPlace pyproject.toml \
      --replace-fail '"setuptools-git-versioning<2"' '"setuptools-git-versioning"'
  '';

  build-system = with python3Packages; [ setuptools setuptools-git-versioning ];
  dependencies = [ python3Packages.oslex ];

  doCheck = false; # no tests in the sdist
  pythonImportsCheck = [ "ufbt" "ufbt.bootstrap" ];

  meta = {
    description = "Micro Flipper Build Tool: build and debug Flipper Zero apps (.fap)";
    homepage = "https://github.com/flipperdevices/flipperzero-ufbt";
    license = lib.licenses.gpl3Plus;
    platforms = lib.platforms.unix;
    mainProgram = "ufbt";
  };
}
