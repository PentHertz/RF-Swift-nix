# OpenSSL 1.1.1w, rebuilt from source. nixpkgs removed the openssl_1_1 attribute
# as EOL, but the WiFi rogue-AP tools (roguehostapd/hostapd-wpe, bundled hostapd
# 2.6) only compile against the OpenSSL 1.1 API, so we resurrect it here for them.
# Not for general use - it is end-of-life; only the old-hostapd builds link it.
{ lib, stdenv, fetchurl, perl, coreutils }:

stdenv.mkDerivation rec {
  pname = "openssl";
  version = "1.1.1w";

  src = fetchurl {
    url = "https://github.com/openssl/openssl/releases/download/OpenSSL_1_1_1w/openssl-${version}.tar.gz";
    hash = "sha256-zzCYlQy02FOtlcCEHx+cbT3BAtzPys1SHZOSUgi3asg=";
  };

  nativeBuildInputs = [ perl ];

  # The upstream Configure/config scripts use /usr/bin/env, which is absent in
  # the Nix build sandbox. Rewrite every script before invoking ./config.
  postPatch = ''
    patchShebangs .
    substituteInPlace config \
      --replace-fail /usr/bin/env ${coreutils}/bin/env
  '';

  # Weak ciphers (SSL3/DES/RC4) enabled: the rogue-AP tools (eaphammer/roguehostapd)
  # rely on them for RADIUS/EAP downgrade attacks. SSLv2 was removed from the 1.1.x
  # code entirely, so `enable-ssl2` is a no-op even upstream.
  configurePhase = ''
    runHook preConfigure
    ./config --prefix=$out --openssldir=$out/etc/ssl shared no-tests \
      enable-ssl3 enable-ssl3-method enable-des enable-rc4 enable-weak-ssl-ciphers \
      -Wno-error --libdir=lib
    runHook postConfigure
  '';

  env.NIX_CFLAGS_COMPILE = "-Wno-error";
  enableParallelBuilding = true;

  # install_sw only: skip man pages / docs (large, unneeded for linking).
  installTargets = [ "install_sw" ];

  meta = {
    description = "OpenSSL 1.1.1w (EOL) - kept only for the legacy hostapd WiFi tools";
    homepage = "https://www.openssl.org/";
    license = lib.licenses.openssl;
    platforms = lib.platforms.linux;
  };
}
