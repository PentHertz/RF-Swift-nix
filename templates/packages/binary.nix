{ lib, stdenv, fetchurl, autoPatchelfHook }:

stdenv.mkDerivation {
  pname = "@NAME@";
  version = "TODO";
  src = fetchurl { url = "@URL@"; hash = lib.fakeHash; };
  nativeBuildInputs = lib.optionals stdenv.hostPlatform.isLinux [ autoPatchelfHook ];
  sourceRoot = ".";
  installPhase = ''
    runHook preInstall
    install -Dm755 @NAME@ "$out/bin/@NAME@"
    runHook postInstall
  '';
  meta = {
    description = "TODO: describe @NAME@";
    homepage = "@URL@";
    license = lib.licenses.unfree;
    sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
    platforms = [ "x86_64-linux" ];
    mainProgram = "@NAME@";
  };
}
