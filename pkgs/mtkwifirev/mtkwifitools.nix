# MtkWifiTools (MtkWifiRev): MediaTek Wi-Fi firmware reverse-engineering tools.
# Matches RF-Swift-images' mtkwifitools_install (hardware):
#
#   * the single-file host tools (patch/RAM/region mergers and splitters, CRC
#     brute force, firmware extraction, the command-ID mapper, ...), built with
#     the images' flags: most sources include both linux/byteorder headers, so
#     big_endian.h's guard is predefined (every target here is little-endian),
#     and -fpermissive for the implicit declarations GCC 14+ rejects;
#     dump_gen4.c gets the open() mode _FORTIFY_SOURCE requires;
#   * mtk_ramreader (live NDS32 RAM reads through mt76 debugfs), x86_64 only:
#     it links the repository's prebuilt x86-64 binutils 2.38 archives (nds32
#     libopcodes). Linked against glibc dynamically rather than -static; its
#     bfd.h also wants ansidecl.h and diagnostics.h, which the images take from
#     binutils-dev: here from libbfd, behind the bundled 2.38 headers;
#   * the scrapers, Ghidra scripts and mt76 patches in share/mtkwifitools.
#
# barepatcher is not packaged: it edits and compiles code in its own checkout
# with a separately downloaded x86-64 NDS32 toolchain.
{ lib, stdenv, fetchFromGitHub, libbfd }:

let
  tools = [
    "add_wf_region.c" "clc_parser.c" "crc_brute.c" "dump_gen4.c" "extract_fw.c"
    "mapperremapper.c" "mt7921_split.c" "MT7961Merge.c" "MT7981Merge.c" "MTKMerge.c"
    "mtkmerge_mt7981_w_rom_patch.c" "mtk_region_customizer.c"
    "patch_add_region_advanced.c" "patch_add_region_fixed.c" "PatchIncorporator.c"
    "patch_ram_merger.c" "patch_reader.c" "patch_splitter.c" "cmd_to_realid/mtk_real_cmd.c"
  ];
  withRamreader = stdenv.hostPlatform.isx86_64;
in
stdenv.mkDerivation {
  pname = "mtkwifitools";
  version = "0-unstable-2025-10-18";

  src = fetchFromGitHub {
    owner = "MtkWifiRev";
    repo = "MtkWifiTools";
    rev = "5876e71d413e409660adf34b15c6ebdc1285a0b5";
    hash = "sha256-j42DupIQTBSI7w3LfnTh0qfDEm9/IOG3JuvN9MWguhg=";
  };

  postPatch = ''
    substituteInPlace dump_gen4.c --replace-fail "O_CREAT | O_WRONLY)" "O_CREAT | O_WRONLY, 0644)"
  '';

  buildPhase = ''
    runHook preBuild
    mkdir -p bin
    for src in ${toString tools}; do
      $CC -std=gnu17 -O2 -w -fpermissive -I. -D_LINUX_BYTEORDER_BIG_ENDIAN_H \
        -o bin/$(basename $src .c) $src
    done
  '' + lib.optionalString withRamreader ''
    (cd ramreader && $CC -std=gnu17 -O2 -w -fpermissive -I./include \
      -idirafter ${lib.getDev libbfd}/include -o ../bin/mtk_ramreader \
      src/ramreader.c libs/libopcodes.a libs/libbfd.a libs/libiberty.a libs/libz.a)
  '' + ''
    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall
    install -Dm755 -t $out/bin bin/*
    mkdir -p $out/share/mtkwifitools
    cp -r README.md MASS MASSv2 ghidra mt76_patch auto_detect android_fw_log \
      $out/share/mtkwifitools/
    runHook postInstall
  '';

  meta = {
    description = "MediaTek Wi-Fi firmware reverse-engineering tools";
    homepage = "https://github.com/MtkWifiRev/MtkWifiTools";
    license = lib.licenses.bsd3;
    # Linux UAPI headers throughout.
    platforms = lib.platforms.linux;
  };
}
