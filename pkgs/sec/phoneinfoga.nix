# PhoneInfoga (sundowndev/phoneinfoga): OSINT framework for phone numbers (CLI
# scanners plus a web UI via `phoneinfoga serve`). Matches RF-Swift-images'
# phoneinfoga_soft_install, which installs the upstream release binary.
#
# nixpkgs dropped it; a source build needs the Vue web client built with yarn and
# go:embed'ed, so like the image we ship upstream's release binaries. They are
# statically linked Go executables (no autoPatchelf needed).
{ lib, stdenv, fetchurl }:

let
  version = "2.11.0";
  asset = {
    "x86_64-linux" = "Linux_x86_64";
    "aarch64-linux" = "Linux_arm64";
    "aarch64-darwin" = "Darwin_arm64";
  }.${stdenv.hostPlatform.system}
    or (throw "phoneinfoga: unsupported platform ${stdenv.hostPlatform.system}");
  # From upstream's phoneinfoga_checksums.txt.
  hash = {
    Linux_x86_64 = "sha256-YXPfxOwAmm/miAaLrFolBkb1qPVkCQmPXtzH5ASxKlI=";
    Linux_arm64 = "sha256-vI7VHj4g/kuCmZqsFqeSX3g1YjRlY7pLJuM8kENM1Ys=";
    Darwin_arm64 = "sha256-XSWYU+aY/BuOH9YgtUFrmBXfW3CaDtrlPKibWatleKI=";
  }.${asset};
in
stdenv.mkDerivation {
  pname = "phoneinfoga";
  inherit version;

  src = fetchurl {
    url = "https://github.com/sundowndev/phoneinfoga/releases/download/v${version}/phoneinfoga_${asset}.tar.gz";
    inherit hash;
  };

  # The tarball holds just the binary, no top-level directory.
  sourceRoot = ".";
  dontConfigure = true;
  dontBuild = true;
  # Already stripped; leave the (ad-hoc signed) Darwin binaries untouched.
  dontStrip = true;

  installPhase = ''
    runHook preInstall
    install -Dm755 phoneinfoga $out/bin/phoneinfoga
    runHook postInstall
  '';

  meta = {
    description = "Information gathering framework for international phone numbers";
    homepage = "https://github.com/sundowndev/phoneinfoga";
    license = lib.licenses.gpl3Only;
    sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
    platforms = [ "x86_64-linux" "aarch64-linux" "aarch64-darwin" ];
    mainProgram = "phoneinfoga";
  };
}
