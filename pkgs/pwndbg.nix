# pwndbg: the GDB plug-in / exploit-dev environment. Modern pwndbg pins a custom
# capstone fork and a private Python venv, so instead of building from source we
# use its official self-contained .deb. Since 2025 that is a relocatable bundle
# under /usr/lib/pwndbg-gdb: gdb, python, capstone and their libraries plus its
# own ld.so, which the launchers invoke explicitly and locate from their own
# path. It is installed as is: patching its ELF files onto the Nix glibc would
# mix two C libraries in one process.
{ lib, stdenv, fetchurl, dpkg }:

stdenv.mkDerivation rec {
  pname = "pwndbg";
  version = "2026.10.22";

  src = fetchurl {
    url = "https://github.com/pwndbg/pwndbg/releases/download/${version}/pwndbg_${version}_amd64.deb";
    hash = "sha256-eIi7mG1j/CMNKfqWvfYVK5zhI7KjsfMz0x+AaENjhIo=";
  };

  nativeBuildInputs = [ dpkg ];

  dontPatchELF = true;
  dontStrip = true;

  unpackPhase = ''
    runHook preUnpack
    dpkg-deb -x $src ./unpacked
    runHook postUnpack
  '';

  # usr/bin/pwndbg is an absolute symlink to /usr/lib/pwndbg-gdb/bin/pwndbg;
  # point bin/ at the store copy instead (the launcher finds the bundle from
  # its own resolved path).
  installPhase = ''
    runHook preInstall
    mkdir -p $out/bin
    cp -r unpacked/usr $out/
    rm $out/usr/bin/pwndbg
    ln -s $out/usr/lib/pwndbg-gdb/bin/pwndbg $out/bin/pwndbg
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
