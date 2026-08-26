# Joern: static analysis / Code Property Graph platform for C/C++/Java/etc.
# (joernio). A JVM app shipped as a self-contained CLI bundle; wrap it with a JDK.
{ lib, stdenv, fetchurl, unzip, makeWrapper, jdk }:

stdenv.mkDerivation rec {
  pname = "joern";
  version = "4.0.609";

  src = fetchurl {
    url = "https://github.com/joernio/joern/releases/download/v${version}/joern-cli-linux-x86_64.zip";
    hash = "sha256-siYXcdlFIdeHABwT1w/UOYwJoVLKCLmJO63yGmjzO+U=";
  };

  nativeBuildInputs = [ unzip makeWrapper ];
  sourceRoot = ".";

  installPhase = ''
    runHook preInstall
    mkdir -p $out/share/joern $out/bin
    cp -r joern-cli/* $out/share/joern/
    for tool in joern joern-parse joern-export joern-scan joern-flow; do
      if [ -f "$out/share/joern/$tool" ]; then
        chmod +x "$out/share/joern/$tool"
        makeWrapper "$out/share/joern/$tool" "$out/bin/$tool" \
          --prefix PATH : "${lib.makeBinPath [ jdk ]}" \
          --set JAVA_HOME "${jdk}"
      fi
    done
    runHook postInstall
  '';

  meta = {
    description = "Code-analysis platform based on Code Property Graphs (C/C++/Java/JS/...)";
    homepage = "https://joern.io/";
    license = lib.licenses.asl20;
    sourceProvenance = [ lib.sourceTypes.binaryBytecode ];
    platforms = [ "x86_64-linux" ];
    mainProgram = "joern";
  };
}
