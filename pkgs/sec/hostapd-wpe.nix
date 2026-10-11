# hostapd-wpe: hostapd 2.11 patched with aircrack-ng's WPE (Wireless Pawn
# Edition) patch, a WPA-Enterprise authentication-server auditing build used to
# collect client EAP credentials for offline cracking. Matches RF-Swift-images'
# hostapdwpe_soft_install (hostapd-2.11.tar.gz + the aircrack-ng
# hostapd-2.11-wpe.patch, `patch -p1`, `make` in hostapd/).
#
# Built standalone rather than from nixpkgs' hostapd because that is 2.12 and the
# patch targets 2.11. The patch's Heartbleed/Cupid code is all gated behind
# OpenSSL < 1.1, so it compiles cleanly against the current OpenSSL 3.x.
#
# The upstream config/certs install to /etc/hostapd-wpe; the store is read-only,
# so we generate the self-signed CA/server/DH material at build time, ship it
# under $out/share/hostapd-wpe, and rewrite the config's cert paths to point
# there - so `hostapd-wpe $out/share/hostapd-wpe/hostapd-wpe.conf` works as-is
# (edit `interface=wlan0` first). The eap_user file and the original cert
# templates/bootstrap are shipped too for users who want their own certs.
# That generated key is world-readable in the store and the same for everyone
# who fetches this build from a binary cache (as with the Docker image): for a
# real engagement, run the bootstrap on a copy and point the config at it.
{ lib, stdenv, fetchurl, pkg-config, openssl, libnl, sqlite }:

let
  hostapdSrc = fetchurl {
    url = "https://w1.fi/releases/hostapd-2.11.tar.gz";
    hash = "sha256-Kz+stjL9T2XjL0v4Kna0tyxQH5laT2LjMCGf567RdHo=";
  };
  # Pinned to an aircrack-ng commit so the patch never shifts under us.
  wpePatch = fetchurl {
    url = "https://raw.githubusercontent.com/aircrack-ng/aircrack-ng/7e2256f38f3590af4c19a6ae14ed79bab02242e6/patches/wpe/hostapd-wpe/hostapd-2.11-wpe.patch";
    hash = "sha256-2UmTZr7ARVQqyTWuN9sSfUE4iE6iuUpEF3vADSVeUx4=";
  };
in
stdenv.mkDerivation {
  pname = "hostapd-wpe";
  version = "2.11-wpe";

  src = hostapdSrc;

  nativeBuildInputs = [ pkg-config ];
  buildInputs = [ openssl libnl sqlite ];

  # -f/--forward so patch never prompts (it reads the patch from stdin). Two
  # hunks do not apply against this hostapd 2.11 tarball and are cosmetic only -
  # the show_version() banner text and a redundant `#include <openssl/rand.h>`
  # removal; every functional WPE hunk applies. The image hits the same rejects.
  postPatch = ''
    patch -p1 -f --forward --no-backup-if-mismatch < ${wpePatch} || true
    rm -f hostapd/main.c.rej src/crypto/tls_openssl.c.rej
  '';

  # libnl headers sit under include/libnl3; the WPE tree also trips modern gcc.
  env.NIX_CFLAGS_COMPILE = "-I${libnl.dev}/include/libnl3 -Wno-error";

  buildPhase = ''
    runHook preBuild
    # The patch adds hostapd/.config (nl80211 + libnl3.2 + openssl + sqlite).
    make -C hostapd -j$NIX_BUILD_CORES hostapd-wpe hostapd_cli-wpe
    # Generate the default self-signed CA/server/client certs + DH params.
    make -C hostapd/certs
    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall
    install -Dm755 hostapd/hostapd-wpe $out/bin/hostapd-wpe
    install -Dm755 hostapd/hostapd_cli-wpe $out/bin/hostapd-wpe_cli

    share=$out/share/hostapd-wpe
    install -Dm644 hostapd/hostapd-wpe.conf $share/hostapd-wpe.conf
    install -Dm644 hostapd/hostapd-wpe.eap_user $share/hostapd-wpe.eap_user
    # Generated material the config points at.
    install -Dm644 -t $share hostapd/certs/ca.pem hostapd/certs/server.pem \
      hostapd/certs/server.key hostapd/certs/dh
    # Original templates + bootstrap, for users who want their own certs.
    mkdir -p $share/certs
    cp -r hostapd/certs/* $share/certs/

    # Point the shipped config at the store copies instead of /etc/hostapd-wpe.
    substituteInPlace $share/hostapd-wpe.conf \
      --replace-fail /etc/hostapd-wpe "$share"
    runHook postInstall
  '';

  meta = {
    description = "hostapd 2.11 with the aircrack-ng WPE patch (WPA-Enterprise credential-auditing AP)";
    homepage = "https://github.com/aircrack-ng/aircrack-ng/tree/master/patches/wpe/hostapd-wpe";
    license = lib.licenses.bsd3; # hostapd's BSD license
    platforms = lib.platforms.linux;
    mainProgram = "hostapd-wpe";
  };
}
