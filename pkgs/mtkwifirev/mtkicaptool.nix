# MtkICAPtool (MtkWifiRev): spectrum captures from a MediaTek Wi-Fi chip's ICAP
# on a rooted MT6769 Android phone. icaptool itself is built with the Android
# NDK and runs on the phone (its sources are in share/mtkicaptool); the PC side
# is the TCP spectrum plotter, `mtk_icap_plot`. Matches RF-Swift-images'
# mtkicaptool_install (hardware), adb included:
#
#   adb forward tcp:9090 tcp:9090; then on the phone: icaptool -i1 / -i11 / -i2
{ lib, stdenvNoCC, fetchFromGitHub, makeWrapper, python3, android-tools }:

let
  python = python3.withPackages (ps: [ ps.numpy ps.matplotlib ps.tkinter ]);
in
stdenvNoCC.mkDerivation {
  pname = "mtkicaptool";
  version = "0-unstable-2025-08-12";

  src = fetchFromGitHub {
    owner = "MtkWifiRev";
    repo = "MtkICAPtool";
    rev = "d829596a88e66382b3afe0f6be1de0c15ff88037";
    hash = "sha256-ZH8uMvt+J44LhWiWNh+H9ZVXphBUEn0KVGf10CCv3PU=";
  };

  nativeBuildInputs = [ makeWrapper ];
  dontConfigure = true;
  dontBuild = true;

  installPhase = ''
    runHook preInstall
    mkdir -p $out/share
    cp -r . $out/share/mtkicaptool
    makeWrapper ${python.interpreter} $out/bin/mtk_icap_plot \
      --add-flags $out/share/mtkicaptool/plot_spectrum_tcp.py \
      --prefix PATH : ${lib.makeBinPath [ android-tools ]}
    runHook postInstall
  '';

  meta = {
    description = "MediaTek Android ICAP spectrum capture: PC-side TCP plotter and phone tool sources";
    homepage = "https://github.com/MtkWifiRev/MtkICAPtool";
    license = lib.licenses.gpl2Only;
    platforms = lib.platforms.unix;
    mainProgram = "mtk_icap_plot";
  };
}
