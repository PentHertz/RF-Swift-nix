# smali / baksmali: the assembler/disassembler for Android's dex format
# (JesusFreke). Packaged from the last upstream fat jars (2.5.2) + a JRE wrapper,
# since the google/smali successor ships only maven libraries, not a runnable CLI.
{ lib, stdenv, fetchurl, makeWrapper, jre }:

stdenv.mkDerivation {
  pname = "smali";
  version = "2.5.2";

  dontUnpack = true;

  smaliJar = fetchurl {
    url = "https://bitbucket.org/JesusFreke/smali/downloads/smali-2.5.2.jar";
    hash = "sha256-lUQplXixb3cdiqjq7+DTcYygNHjBbzw1by/PE2a/sRY=";
  };
  baksmaliJar = fetchurl {
    url = "https://bitbucket.org/JesusFreke/smali/downloads/baksmali-2.5.2.jar";
    hash = "sha256-0xFiSMzk+C7Fox63+V7nXa/0Ld9u7Qq1c5c9xT+60uU=";
  };

  nativeBuildInputs = [ makeWrapper ];

  installPhase = ''
    runHook preInstall
    mkdir -p $out/share/smali $out/bin
    cp $smaliJar $out/share/smali/smali.jar
    cp $baksmaliJar $out/share/smali/baksmali.jar
    makeWrapper ${jre}/bin/java $out/bin/smali --add-flags "-jar $out/share/smali/smali.jar"
    makeWrapper ${jre}/bin/java $out/bin/baksmali --add-flags "-jar $out/share/smali/baksmali.jar"
    runHook postInstall
  '';

  meta = {
    description = "Assembler/disassembler for Android dex (smali + baksmali)";
    homepage = "https://github.com/JesusFreke/smali";
    license = lib.licenses.bsd3;
    platforms = lib.platforms.linux;
    mainProgram = "baksmali";
  };
}
