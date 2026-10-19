# MtkCSIdump (MtkWifiRev): live Wi-Fi CSI from a MediaTek mt7981 router
# (OpenWrt One). The CSIdump server runs on the router (prebuilt in upstream's
# v0.1 release; its sources are in share/mtkcsidump); the PC side is the PyQt5
# GUI client, `mtk_csi_client <router ip> <udp port>`. Matches RF-Swift-images'
# mtkcsidump_install (hardware). The README's 13 MB demo GIF is left out.
{ lib, stdenvNoCC, fetchFromGitHub, python3, qt5 }:

let
  python = python3.withPackages (ps: [ ps.pyqt5 ps.pyqtgraph ps.numpy ps.matplotlib ]);
in
stdenvNoCC.mkDerivation {
  pname = "mtkcsidump";
  version = "0.1-unstable-2025-12-31";

  src = fetchFromGitHub {
    owner = "MtkWifiRev";
    repo = "MtkCSIdump";
    rev = "276b4b0814a283dcbc6544a76033e0e37154f092";
    hash = "sha256-NCsNgvFu4CU1MPoxBa+oscGxu5/u2bHl1CTyErz5TUo=";
  };

  # makeQtWrapper sets the Qt plugin paths PyQt5 needs to open a window.
  nativeBuildInputs = [ qt5.wrapQtAppsHook ];
  buildInputs = [ qt5.qtbase ] ++ lib.optionals stdenvNoCC.hostPlatform.isLinux [ qt5.qtwayland ];
  dontWrapQtApps = true;
  dontConfigure = true;
  dontBuild = true;

  installPhase = ''
    runHook preInstall
    share=$out/share/mtkcsidump
    mkdir -p $share
    cp -r csi_udp_client_gui.py README.md CMakeLists.txt main.cpp md.cpp md.h \
      motion_detector.cpp motion_detector.h parsers wifi_drv_api $share/
    makeQtWrapper ${python.interpreter} $out/bin/mtk_csi_client \
      --add-flags $share/csi_udp_client_gui.py
    runHook postInstall
  '';

  meta = {
    description = "MediaTek Wi-Fi CSI dump: PyQt5 live client and router server sources";
    homepage = "https://github.com/MtkWifiRev/MtkCSIdump";
    license = lib.licenses.asl20;
    platforms = lib.platforms.linux ++ lib.platforms.darwin;
    mainProgram = "mtk_csi_client";
  };
}
