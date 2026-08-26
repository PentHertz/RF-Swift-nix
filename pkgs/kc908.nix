# KC908 / KCSDI (Deepace): the KCSDI device/calibration application plus the
# SDR++ source plugin, from the PentHertz mirrors RF Swift uses. KCSDI ships as an
# AppImage (wrapped with appimageTools); the SDR++ plugin is a prebuilt .so.
{ lib, appimageTools, fetchurl, stdenv, autoPatchelfHook, libusb1 }:

let
  pname = "kc908";
  version = "0.5.11-72";
  kcsdiSrc = fetchurl {
    url = "https://github.com/PentHertz/rfswift_deepace_install/releases/download/nightly/KCSDI-v0.5.11-72-linux-x86_64.1.appimage";
    hash = "sha256-hEUzUAvR9zBdb6UAI9bMSifB++j+UgshBa+dSoW2X10=";
  };
  sdrppPlugin = fetchurl {
    url = "https://github.com/PentHertz/SDRPlusPlus/releases/download/KC908/kcsdr_source-amd64.so";
    hash = "sha256-g3+ZG2a1pWhCDfPkduYtzPCeKfDbH5a1LboLX42IF/o=";
  };
  # The SDR++ source plugin, autopatched to the Nix libraries.
  kcsdrPlugin = stdenv.mkDerivation {
    pname = "kcsdr-sdrpp-plugin";
    inherit version;
    dontUnpack = true;
    nativeBuildInputs = [ autoPatchelfHook ];
    buildInputs = [ libusb1 stdenv.cc.cc.lib ];
    autoPatchelfIgnoreMissingDeps = true;
    installPhase = ''
      install -Dm444 ${sdrppPlugin} $out/lib/sdrpp/plugins/kcsdr_source.so
    '';
    meta.platforms = [ "x86_64-linux" ];
  };
in
appimageTools.wrapType2 {
  inherit pname version;
  src = kcsdiSrc;

  extraInstallCommands = ''
    # Ship the SDR++ KC908 source plugin alongside the KCSDI app.
    mkdir -p $out/lib/sdrpp/plugins
    ln -sf ${kcsdrPlugin}/lib/sdrpp/plugins/kcsdr_source.so $out/lib/sdrpp/plugins/ 2>/dev/null || true
    ln -sf $out/bin/${pname} $out/bin/kcsdi 2>/dev/null || true
  '';

  meta = {
    description = "Deepace KC908 / KCSDI device software (AppImage) + SDR++ source plugin";
    homepage = "https://www.deepace.net/";
    license = lib.licenses.unfree;
    sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
    platforms = [ "x86_64-linux" ];
    mainProgram = "kc908";
  };
}
