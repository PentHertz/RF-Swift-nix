# w1700k-sdr (h0m3us3r): the Gemtek W1700K Wi-Fi 7 router's MediaTek MT7996 as
# an SDR. Matches RF-Swift-images' w1700ksdr_sdrhacks_install (sdr_hacks):
#
#   * host tools w1700k-stream, w1700k-spectrum (web page compiled in) and
#     sdr-recv, built portably (upstream suggests -march=native) and without
#     -Werror;
#   * the MT7996 firmware set (ROM patch, WM, WA: own code, no MediaTek byte),
#     built here with clang/ld.lld/llvm-objcopy for bare-metal RV32 and the
#     openssl command, into share/w1700k-sdr/firmware/build;
#   * the `w1700k` CLI (stdlib Python, drives the router over ssh), installed
#     with the repository layout it expects: it reads
#     <repo>/firmware/build/firmware.json by default.
#
# The router OS itself (root `make`: Buildroot, Linux, U-Boot, ~500 MB of
# downloads) is not built, as in the images.
{ lib, stdenv, fetchFromGitHub, makeWrapper, fftwFloat, zlib, python3, openssl
, llvmPackages, openssh }:

stdenv.mkDerivation {
  pname = "w1700k-sdr";
  version = "0-unstable-2026-10-13";

  src = fetchFromGitHub {
    owner = "h0m3us3r";
    repo = "w1700k-sdr";
    rev = "0b0413e4309f0c083702fa4eb2d1c2bca4532163";
    hash = "sha256-6SHwBNGl57aStMsRjtjGREcLgERw0vLVJMuoB15YX0c=";
  };

  # The firmware is freestanding RV32 code: the unwrapped clang, so the cc
  # wrapper adds no host flags (hardening, -isystem) to it.
  nativeBuildInputs = [
    makeWrapper python3 openssl
    llvmPackages.clang-unwrapped llvmPackages.lld llvmPackages.llvm
  ];
  buildInputs = [ fftwFloat zlib ];

  makeFlags = [ "WARNINGS=-Wall -Wextra" "PREFIX=${placeholder "out"}" ];

  buildPhase = ''
    runHook preBuild
    for d in stream spectrum recv; do
      make -C host/$d -j$NIX_BUILD_CORES ''${makeFlags[@]} CXX=$CXX CC=$CC
    done
    patchShebangs host/spectrum/embed.sh
    make -C firmware
    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall
    for d in stream spectrum recv; do
      make -C host/$d install ''${makeFlags[@]}
    done
    share=$out/share/w1700k-sdr
    mkdir -p $share/host $share/firmware
    cp -r host/w1700k host/bin $share/host/
    cp -r firmware/build $share/firmware/
    cp -r README.md docs $share/
    makeWrapper ${python3.interpreter} $out/bin/w1700k \
      --add-flags $share/host/bin/w1700k \
      --prefix PATH : ${lib.makeBinPath [ openssh ]}
    runHook postInstall
  '';

  meta = {
    description = "Gemtek W1700K (MediaTek MT7996) Wi-Fi 7 router as an SDR: host tools, firmware and CLI";
    homepage = "https://github.com/h0m3us3r/w1700k-sdr";
    # The host tools, firmware and CLI are MIT (per-file SPDX); the router
    # kernel module (GPL-2.0) is not part of this package.
    license = lib.licenses.mit;
    platforms = lib.platforms.linux;
    mainProgram = "w1700k";
  };
}
