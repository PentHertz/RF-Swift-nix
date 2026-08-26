# Ghidra, latest official release (matches RF Swift, which installs the release
# zip rather than the sometimes-behind distro/nixpkgs build).
{ lib, stdenv, fetchzip, makeWrapper, autoPatchelfHook, jdk21 }:

stdenv.mkDerivation rec {
  pname = "ghidra-latest";
  version = "12.1.3";
  releaseDate = "20260817";

  src = fetchzip {
    url = "https://github.com/NationalSecurityAgency/ghidra/releases/download/Ghidra_${version}_build/ghidra_${version}_PUBLIC_${releaseDate}.zip";
    hash = "sha256-YfzkxneaVPc17CBNao7WSmed2Ipp0dOJ2u/cOYotk+s=";
  };

  nativeBuildInputs = [ makeWrapper autoPatchelfHook ];
  buildInputs = [ stdenv.cc.cc.lib ];

  # Ghidra ships prebuilt native helpers (decompiler, demangler); let
  # autoPatchelf point them at the Nix loader. Ignore any it cannot resolve.
  autoPatchelfIgnoreMissingDeps = true;

  dontBuild = true;
  dontConfigure = true;

  installPhase = ''
    runHook preInstall
    mkdir -p $out/opt/ghidra $out/bin
    cp -r . $out/opt/ghidra/
    for prog in ghidraRun support/analyzeHeadless; do
      name=$(basename "$prog")
      [ "$name" = "ghidraRun" ] && name=ghidra
      makeWrapper "$out/opt/ghidra/$prog" "$out/bin/$name" \
        --prefix PATH : ${lib.makeBinPath [ jdk21 ]} \
        --set JAVA_HOME ${jdk21}
    done
    runHook postInstall
  '';

  meta = {
    description = "Ghidra software reverse engineering framework (latest official release)";
    homepage = "https://ghidra-sre.org/";
    license = lib.licenses.asl20;
    platforms = [ "x86_64-linux" "aarch64-linux" ];
    mainProgram = "ghidra";
  };
}
