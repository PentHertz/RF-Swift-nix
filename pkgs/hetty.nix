# Hetty: an HTTP toolkit for security research (a web-UI MITM proxy, dstotijn).
# Shipped as a self-contained Go release binary (as RF Swift installs it).
{ lib, stdenv, fetchurl, autoPatchelfHook }:

stdenv.mkDerivation rec {
  pname = "hetty";
  version = "0.7.0";

  src = fetchurl {
    url = "https://github.com/dstotijn/hetty/releases/download/v${version}/hetty_${version}_Linux_x86_64.tar.gz";
    hash = "sha256-G/FQGQe+sltVCDeBP6gAuaVlMrC0R6YXwTPAfd+7wY0=";
  };

  nativeBuildInputs = [ autoPatchelfHook ];
  sourceRoot = ".";

  installPhase = ''
    runHook preInstall
    install -Dm755 hetty $out/bin/hetty
    runHook postInstall
  '';

  meta = {
    description = "HTTP toolkit for security research (proxy with a web UI)";
    homepage = "https://github.com/dstotijn/hetty";
    license = lib.licenses.mit;
    sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
    platforms = [ "x86_64-linux" ];
    mainProgram = "hetty";
  };
}
