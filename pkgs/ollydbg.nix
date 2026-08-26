# OllyDBG 2.01: the classic 32-bit Windows debugger. No Linux build exists, but it
# runs under Wine (a common Linux RE workflow), so ship it Wine-wrapped.
{ lib, stdenv, fetchurl, unzip, makeWrapper, wine }:

stdenv.mkDerivation {
  pname = "ollydbg";
  version = "2.01";

  src = fetchurl {
    url = "http://www.ollydbg.de/odbg201.zip";
    hash = "sha256-KSROVRvjHzR9sAUDxRIFgIb1W0PJPBrpNymxXObgh6U=";
  };

  nativeBuildInputs = [ unzip makeWrapper ];
  sourceRoot = ".";

  installPhase = ''
    runHook preInstall
    mkdir -p $out/opt/ollydbg $out/bin
    cp -r . $out/opt/ollydbg/
    exe=$(find $out/opt/ollydbg -iname 'ollydbg.exe' | head -1)
    makeWrapper ${wine}/bin/wine $out/bin/ollydbg \
      --add-flags "$exe" --set WINEDEBUG "-all"
    runHook postInstall
  '';

  meta = {
    description = "OllyDBG 2.01 32-bit Windows debugger, run under Wine";
    homepage = "https://www.ollydbg.de/";
    license = lib.licenses.unfree; # freeware, no redistribution license
    sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
    platforms = [ "x86_64-linux" ];
    mainProgram = "ollydbg";
  };
}
