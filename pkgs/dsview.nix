# DSView (DreamSourceLab logic analyzer GUI), from the PentHertz-built .deb that
# RF Swift ships (github.com/PentHertz/DSView releases). Packaged as a binary:
# extract the .deb and autoPatchelf it to the Nix Qt5 libraries.
#
# Opt-in (pkg-dsview): pin the .deb hash on first build, and adjust the Qt/lib
# set if autoPatchelf reports anything missing.
{ lib, stdenv, fetchurl, dpkg, autoPatchelfHook, wrapQtAppsHook
, qtbase, qtsvg, libusb1, glib, zlib, fftw, fftwFloat, boost, python3 }:

stdenv.mkDerivation rec {
  pname = "dsview";
  version = "1.3.4";

  src = fetchurl {
    url = "https://github.com/PentHertz/DSView/releases/download/v${version}/dsview_${version}-1_amd64.deb";
    hash = "sha256-UzjvaDVSIlq5HcIWVwwex4qSA6sE7A58RnDs7M9bSGc=";
  };

  nativeBuildInputs = [ dpkg autoPatchelfHook wrapQtAppsHook ];
  buildInputs = [ qtbase qtsvg libusb1 glib zlib fftw fftwFloat boost python3 stdenv.cc.cc.lib ];

  unpackPhase = ''
    runHook preUnpack
    dpkg-deb -x $src ./unpacked
    runHook postUnpack
  '';

  installPhase = ''
    runHook preInstall
    mkdir -p $out
    cp -r unpacked/usr/* $out/ 2>/dev/null || cp -r unpacked/* $out/
    runHook postInstall
  '';

  meta = {
    description = "DSView: DreamSourceLab logic analyzer / oscilloscope GUI (PentHertz build)";
    homepage = "https://github.com/PentHertz/DSView";
    license = lib.licenses.gpl3Plus;
    platforms = [ "x86_64-linux" ];
    mainProgram = "DSView";
  };
}
