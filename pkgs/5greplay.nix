# 5Greplay: 5G NAS/NGAP fuzzing & replay tool (Montimage), built against mmt-dpi.
{ lib, stdenv, fetchFromGitHub, mmt-dpi, libpcap, libxml2, libconfuse, lksctp-tools, icu, xz, zlib }:

stdenv.mkDerivation {
  pname = "5greplay";
  version = "unstable-2024";

  src = fetchFromGitHub {
    owner = "Montimage";
    repo = "5Greplay";
    rev = "master";
    hash = "sha256-c3lETZHb4ppB28P8HD+w9yz67t5g8J1jToTu4Trgq94=";
  };

  buildInputs = [ mmt-dpi libpcap libxml2 libconfuse lksctp-tools icu xz zlib ];
  # gcc-15 defaults to C23, where `f()` means `f(void)`; this old code relies on
  # K&R "unspecified args" (e.g. `void conf_release()`), so compile as gnu11.
  env.NIX_CFLAGS_COMPILE = "-std=gnu11 -I${libxml2.dev}/include/libxml2 -Wno-error -Wno-incompatible-pointer-types -Wno-implicit-function-declaration -Wno-int-conversion -fcommon";

  # Upstream forces static system libs (-l:libX.a); nixpkgs ships them shared, so
  # link them dynamically. The mmt-dpi libs stay as-is.
  postPatch = ''
    for mk in $(find . -name Makefile); do
      sed -i \
        -e 's/-l:libconfuse\.a/-lconfuse/g' \
        -e 's/-l:libxml2\.a/-lxml2/g' \
        -e 's/-l:libicuuc\.a/-licuuc/g' \
        -e 's/-l:libicudata\.a/-licudata/g' \
        -e 's/-l:libz\.a/-lz/g' \
        -e 's/-l:liblzma\.a/-llzma/g' \
        -e 's/-l:libsctp\.a/-lsctp/g' \
        -e 's/-l:libpcap\.so/-lpcap/g' \
        "$mk"
    done
  '';

  buildPhase = ''
    runHook preBuild
    make -j$NIX_BUILD_CORES MMT_BASE=${mmt-dpi}
    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall
    mkdir -p $out/bin $out/share/5greplay
    bin=$(find . -maxdepth 2 -name '5greplay' -type f -perm -u+x | head -1)
    [ -n "$bin" ] && install -Dm755 "$bin" $out/bin/5greplay
    cp -r rules $out/share/5greplay/ 2>/dev/null || true
    runHook postInstall
  '';

  meta = {
    description = "5G NAS/NGAP fuzzing and replay tool";
    homepage = "https://github.com/Montimage/5Greplay";
    license = lib.licenses.gpl3Plus;
    platforms = [ "x86_64-linux" ];
    mainProgram = "5greplay";
  };
}
