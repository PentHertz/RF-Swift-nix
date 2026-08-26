# crypto1_bs: bit-sliced MIFARE Crypto1 brute-forcer (aczid), built the way RF
# Swift builds it for miLazyCracker: crypto1_bs + the crapto1-v3.3 / craptev1-v1.1
# trees (from PentHertz's rfid-proj mirror) + miLazyCracker's crypto1_bs.diff.
# Produces solve_bs / solve_piwi_bs / solve_piwi / libnfc_crypto1_crack.
{ lib, stdenv, fetchFromGitHub, fetchurl, libnfc }:

let
  crapto1 = fetchurl {
    url = "https://github.com/PentHertz/rfid-proj/releases/download/v0/crapto1-v3.3.tar.xz";
    hash = "sha256-wRbfY9iL6ilmuYz3cXCnOCWFeJueRwiHZuFnpmYjCiA=";
  };
  craptev1 = fetchurl {
    url = "https://github.com/PentHertz/rfid-proj/releases/download/v0/craptev1-v1.1.tar.xz";
    hash = "sha256-JVCqkvy1BLYtvEqXjFHSg/NO0tOT6gxVRE3Ev1zTxOQ=";
  };
  # miLazyCracker's patch adapts crypto1_bs's Makefile/paths. It was authored
  # against crypto1_bs commit 89de1ba5, so pin to that.
  crypto1bsPatch = fetchurl {
    url = "https://raw.githubusercontent.com/nfc-tools/miLazyCracker/master/crypto1_bs.diff";
    hash = "sha256-e32DA3p6TkLeFNPcMaFWqG/ho/jjOs/gLUx+5by0IVU=";
  };
in
stdenv.mkDerivation {
  pname = "crypto1-bs";
  version = "unstable-89de1ba5";

  src = fetchFromGitHub {
    owner = "aczid";
    repo = "crypto1_bs";
    rev = "89de1ba5ef5c82ffc3dc5bbe3eb61229811f9602";
    hash = "sha256-rQuOZryy2cOH4VgQK2/g2t7heufVlXf0wfR+7MDstSU=";
  };

  buildInputs = [ libnfc ];

  postPatch = ''
    patch -p1 < ${crypto1bsPatch} || echo "patch partially applied (tolerated, as upstream does)"
    tar Jxf ${craptev1}
    mkdir -p crapto1-v3.3
    tar Jxf ${crapto1} -C crapto1-v3.3
    # Pin to a portable baseline instead of -march=native so the build is
    # reproducible and cacheable across x86_64 machines.
    sed -i 's/-march=native//g' Makefile
  '';

  env.NIX_CFLAGS_COMPILE = "-Wno-error";

  installPhase = ''
    runHook preInstall
    mkdir -p $out/bin
    for b in solve_bs solve_piwi_bs solve_piwi libnfc_crypto1_crack; do
      [ -f "$b" ] && install -Dm755 "$b" "$out/bin/$b"
    done
    runHook postInstall
  '';

  meta = {
    description = "Bit-sliced MIFARE Classic Crypto1 brute-forcer (crypto1_bs + crapto1/craptev1)";
    homepage = "https://github.com/aczid/crypto1_bs";
    license = lib.licenses.gpl3Plus;
    platforms = [ "x86_64-linux" ];
  };
}
