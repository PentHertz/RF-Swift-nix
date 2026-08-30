# KC908 / KCSDI (Deepace): the KCSDI device/calibration application, from the
# PentHertz mirror RF Swift uses, wrapped with appimageTools. The SDR++ KC908
# source is no longer a prebuilt .so dropped next to it: sdrpp-hydrasdr
# compiles the fork's kcsdr_source against kc908-sdk (pkgs/vendor), so it
# matches the SDR++ core it loads into.
{ lib, appimageTools, fetchurl }:

let
  pname = "kc908";
  version = "0.5.11-72";
  kcsdiSrc = fetchurl {
    url = "https://github.com/PentHertz/rfswift_deepace_install/releases/download/nightly/KCSDI-v0.5.11-72-linux-x86_64.1.appimage";
    hash = "sha256-hEUzUAvR9zBdb6UAI9bMSifB++j+UgshBa+dSoW2X10=";
  };
in
appimageTools.wrapType2 {
  inherit pname version;
  src = kcsdiSrc;

  extraInstallCommands = ''
    ln -sf $out/bin/${pname} $out/bin/kcsdi 2>/dev/null || true
  '';

  meta = {
    description = "Deepace KC908 / KCSDI device software (AppImage)";
    homepage = "https://www.deepace.net/";
    license = lib.licenses.unfree;
    sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
    platforms = [ "x86_64-linux" ];
    mainProgram = "kc908";
  };
}
