# x64dbg: the open-source Windows x86/x64 debugger. It has no Linux build, but it
# runs well under Wine (a common Linux reverse-engineering workflow), so we ship
# the official snapshot wrapped with Wine (WoW64 for the 32- and 64-bit engines).
# Wine is large; on a disk-constrained builder this pulls a big closure.
{ lib, stdenv, fetchurl, unzip, makeWrapper, wine }:

stdenv.mkDerivation {
  pname = "x64dbg";
  version = "2026.05.27";

  src = fetchurl {
    url = "https://github.com/x64dbg/x64dbg/releases/download/2026.05.27/snapshot_2026-05-27_12-11.zip";
    hash = "sha256-1Blm38W0NaNyeYJFMAygq3u45Ivb9IUSxvsg/MpCdpc=";
  };

  nativeBuildInputs = [ unzip makeWrapper ];
  sourceRoot = ".";

  installPhase = ''
    runHook preInstall
    mkdir -p $out/opt/x64dbg $out/bin
    cp -r release/* $out/opt/x64dbg/
    # Individual engines, plus the x96dbg launcher (auto-selects 32/64).
    makeWrapper ${wine}/bin/wine $out/bin/x64dbg \
      --add-flags "$out/opt/x64dbg/x64/x64dbg.exe" --set WINEDEBUG "-all"
    makeWrapper ${wine}/bin/wine $out/bin/x32dbg \
      --add-flags "$out/opt/x64dbg/x32/x32dbg.exe" --set WINEDEBUG "-all"
    makeWrapper ${wine}/bin/wine $out/bin/x96dbg \
      --add-flags "$out/opt/x64dbg/x96dbg.exe" --set WINEDEBUG "-all"
    runHook postInstall
  '';

  meta = {
    description = "x64dbg Windows x86/x64 debugger, run under Wine";
    homepage = "https://x64dbg.com/";
    license = lib.licenses.gpl3Plus;
    sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
    platforms = [ "x86_64-linux" ];
    mainProgram = "x96dbg";
  };
}
