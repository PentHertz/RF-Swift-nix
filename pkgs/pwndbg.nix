# pwndbg: the GDB plug-in / exploit-dev environment. Modern pwndbg pins a custom
# capstone fork and a private Python venv, so instead of building from source we
# use its official self-contained .deb (bundles gdb + python + capstone under
# /usr/lib/pwndbg) and autoPatchelf it to the Nix libraries.
{ lib, stdenv, fetchurl, dpkg, autoPatchelfHook, makeWrapper
, ncurses, readline, gmp, expat, zlib, xz, python3, libedit, mpfr }:

stdenv.mkDerivation rec {
  pname = "pwndbg";
  version = "2024.08.29";

  src = fetchurl {
    url = "https://github.com/pwndbg/pwndbg/releases/download/${version}/pwndbg_${version}_amd64.deb";
    hash = "sha256-G3IZ8CRUUM0t3ZbefdmnFh9bSn2Aibyz9PpGOA66OcQ=";
  };

  nativeBuildInputs = [ dpkg autoPatchelfHook makeWrapper ];
  buildInputs = [
    ncurses readline gmp mpfr expat zlib xz python3 libedit stdenv.cc.cc.lib
  ];
  # The bundle ships many of its own .so files; ignore deps it satisfies itself.
  autoPatchelfIgnoreMissingDeps = true;

  unpackPhase = ''
    runHook preUnpack
    dpkg-deb -x $src ./unpacked
    runHook postUnpack
  '';

  installPhase = ''
    runHook preInstall
    mkdir -p $out
    cp -r unpacked/usr $out/
    # /usr/bin/pwndbg is the entry launcher into the bundled gdb.
    if [ -e "$out/usr/bin/pwndbg" ]; then
      mkdir -p $out/bin
      ln -sf $out/usr/bin/pwndbg $out/bin/pwndbg
    fi
    runHook postInstall
  '';

  meta = {
    description = "Exploit-development and reverse-engineering plugin for GDB (bundled build)";
    homepage = "https://pwndbg.re/";
    license = lib.licenses.mit;
    sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
    platforms = [ "x86_64-linux" ];
    mainProgram = "pwndbg";
  };
}
