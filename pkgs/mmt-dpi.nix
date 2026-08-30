# MMT-DPI: Montimage's deep-packet-inspection SDK (open source), the dependency
# 5Greplay builds against.
{ lib, stdenv, fetchFromGitHub, libpcap, libxml2, libconfuse }:

stdenv.mkDerivation {
  pname = "mmt-dpi";
  version = "unstable-2024";

  src = fetchFromGitHub {
    owner = "Montimage";
    repo = "mmt-dpi";
    rev = "83eac9a285f74901140a8b59d60bb51870a49793";
    hash = "sha256-gB8I/5UOTBI1DH9ddkWirPJxOSMnVUc/GYVd76MrNcY=";
  };

  buildInputs = [ libpcap libxml2 libconfuse ];
  env.NIX_CFLAGS_COMPILE = "-Wno-error -Wno-incompatible-pointer-types -Wno-implicit-function-declaration -Wno-int-conversion -fcommon";

  buildPhase = ''
    runHook preBuild
    make -C sdk -j$NIX_BUILD_CORES MMT_BASE=$out
    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall
    make -C sdk install MMT_BASE=$out INSTALL_DIR=$out
    # The install stages versioned symlinks for optional plugin libs (fuzz,
    # security) that this core build doesn't produce; drop the dangling ones.
    find $out -xtype l -delete
    runHook postInstall
  '';

  meta = {
    description = "Montimage MMT deep-packet-inspection SDK";
    homepage = "https://github.com/Montimage/mmt-dpi";
    license = lib.licenses.gpl3Plus;
    # Plain C, no arch-specific code; x86_64 and aarch64 (the images build arm64).
    platforms = [ "x86_64-linux" "aarch64-linux" ];
  };
}
