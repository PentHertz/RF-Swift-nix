# MtkMon (MtkWifiRev): a Nexmon port to MediaTek's NDS32 Wi-Fi firmware
# (firmware patching; working for mt7981 through the ROM patch and mt7915).
# Sources only, as RF-Swift-images' mtkmon_install clones them (hardware):
# building patches needs the x86-64 NDS32 gcc 8 toolchain its buildtools fetch
# and build (cd buildtools && make), then make -C buildtools/gcc-nexmon-plugin;
# source setup_env.sh; make in patches/<chip>/... - in a writable copy of
# share/mtkmon.
{ lib, stdenvNoCC, fetchFromGitHub }:

stdenvNoCC.mkDerivation {
  pname = "mtkmon";
  version = "0-unstable-2026-05-23";

  src = fetchFromGitHub {
    owner = "MtkWifiRev";
    repo = "MtkMon";
    rev = "698c1de74507b4df1ab4351c89aa794890b93918";
    hash = "sha256-Om9DoO/KcgwGs9/8Jxvj765hoJ7K5T7W/nOi9wphu+U=";
  };

  dontConfigure = true;
  dontBuild = true;
  dontPatchShebangs = true;
  dontFixup = true;

  installPhase = ''
    runHook preInstall
    mkdir -p $out/share
    cp -r . $out/share/mtkmon
    runHook postInstall
  '';

  meta = {
    description = "Nexmon port for MediaTek NDS32 Wi-Fi firmware patching (sources)";
    homepage = "https://github.com/MtkWifiRev/MtkMon";
    # The repository carries no licence file; Nexmon's own licence restricts
    # use, so treat it as unfree.
    license = lib.licenses.unfree;
    platforms = lib.platforms.all;
  };
}
