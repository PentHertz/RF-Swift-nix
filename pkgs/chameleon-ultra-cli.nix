# ChameleonUltra host CLI (RfidResearchGroup): the Python client that drives the
# Chameleon Ultra/Lite RFID emulator over serial, with the C key-recovery
# helpers (software/src: nested, staticnested*, darkside, mfkey*, hardnested)
# its Mifare attack commands run.
{ lib, python3Packages, fetchFromGitHub, makeWrapper, cmake, openssl }:

let
  pick = names: lib.filter (x: x != null) (map (n: python3Packages.${n} or null) names);
  # software/src FetchContent-pulls xz (liblzma, for hardnested's compressed
  # tables) from GitHub; the build sandbox has no network, so hand CMake the
  # same tag as a pre-fetched source.
  xzSrc = fetchFromGitHub {
    owner = "tukaani-project";
    repo = "xz";
    tag = "v5.8.1";
    hash = "sha256-vGUNoX5VTM0aQ5GmBPXip97WGN9vaVrQLE9msToZyKs=";
  };
in
python3Packages.buildPythonApplication {
  pname = "chameleon-ultra-cli";
  version = "2-unstable";
  format = "other";

  src = fetchFromGitHub {
    owner = "RfidResearchGroup";
    repo = "ChameleonUltra";
    rev = "0c1d5791b46e8ac1a87cb8e356f180b1394fb827";
    hash = "sha256-wUkw6uM+XPRgODRElJmSZM3AbD0X2balRgEVrn5V6V8=";
  };

  nativeBuildInputs = [ makeWrapper cmake ];
  # mfulc_des_brute (Ultralight-C DES brute force) links libcrypto.
  buildInputs = [ openssl ];
  propagatedBuildInputs = pick [ "pyserial" "colorama" "prompt-toolkit" ];
  dontUseCmakeConfigure = true;
  doCheck = false;

  # The CLI looks for the helpers in bin/ next to its scripts, which is where
  # this CMake project writes them (EXECUTABLE_OUTPUT_PATH = ../script/bin), so
  # installPhase's copy of software/script picks them up.
  buildPhase = ''
    runHook preBuild
    cmake -S software/src -B build-tools -DCMAKE_BUILD_TYPE=Release \
      -DFETCHCONTENT_FULLY_DISCONNECTED=ON -DFETCHCONTENT_SOURCE_DIR_XZ=${xzSrc}
    cmake --build build-tools -j$NIX_BUILD_CORES
    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall
    mkdir -p $out/share/chameleon-ultra $out/bin
    cp -r software/script/* $out/share/chameleon-ultra/
    makeWrapper ${python3Packages.python.interpreter} $out/bin/chameleon_cli \
      --add-flags "$out/share/chameleon-ultra/chameleon_cli_main.py" \
      --chdir "$out/share/chameleon-ultra" \
      --prefix PYTHONPATH : "$out/share/chameleon-ultra:$PYTHONPATH"
    runHook postInstall
  '';

  meta = {
    description = "ChameleonUltra host CLI client (RFID emulator control)";
    homepage = "https://github.com/RfidResearchGroup/ChameleonUltra";
    license = lib.licenses.agpl3Only;
    mainProgram = "chameleon_cli";
  };
}
