# miLazyCracker: one-shot wrapper that runs mfoc then falls back to the bit-sliced
# Crypto1 dark-side/nested crack (libnfc_crypto1_crack) to recover MIFARE keys.
{ lib, stdenv, fetchFromGitHub, makeWrapper, crypto1-bs, mfoc, mfcuk, libnfc }:

stdenv.mkDerivation {
  pname = "milazycracker";
  version = "unstable";

  src = fetchFromGitHub {
    owner = "nfc-tools";
    repo = "miLazyCracker";
    rev = "b4f0d35df0da8ec8f06e7a285099dbf0978d0ad2";
    hash = "sha256-e73MCVq8KXe0xvAI5WY++soON2cFekgHfRrGFD55osI=";
  };

  nativeBuildInputs = [ makeWrapper ];
  dontBuild = true;

  installPhase = ''
    runHook preInstall
    install -Dm755 miLazyCracker.sh $out/bin/miLazyCracker
    wrapProgram $out/bin/miLazyCracker \
      --prefix PATH : "${lib.makeBinPath [ crypto1-bs mfoc mfcuk libnfc ]}"
    runHook postInstall
  '';

  meta = {
    description = "Automated MIFARE Classic key recovery (mfoc + bit-sliced Crypto1 crack)";
    homepage = "https://github.com/nfc-tools/miLazyCracker";
    license = lib.licenses.gpl3Plus;
    platforms = [ "x86_64-linux" ];
    mainProgram = "miLazyCracker";
  };
}
