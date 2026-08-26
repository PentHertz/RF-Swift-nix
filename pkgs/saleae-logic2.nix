# Saleae Logic 2: the logic-analyzer GUI for Saleae devices. Free (unfree license)
# AppImage download, wrapped with appimageTools (Electron app). Same URL RF Swift
# uses (downloads2.saleae.com).
{ lib, appimageTools, fetchurl }:

let
  pname = "saleae-logic2";
  version = "2.4.46";
  src = fetchurl {
    url = "https://downloads2.saleae.com/logic2/Logic-${version}-linux-x64.AppImage";
    hash = "sha256-goMu0NMWZwHX9PffV6YgtyGiOIPgz+jy6OlaLmcg1vI=";
  };
  appimageContents = appimageTools.extractType2 { inherit pname version src; };
in
appimageTools.wrapType2 {
  inherit pname version src;

  extraInstallCommands = ''
    install -Dm444 ${appimageContents}/Logic.desktop -t $out/share/applications 2>/dev/null || true
    mkdir -p $out/bin && ln -sf $out/bin/${pname} $out/bin/logic2 2>/dev/null || true
  '';

  meta = {
    description = "Saleae Logic 2 logic-analyzer software";
    homepage = "https://www.saleae.com/";
    license = lib.licenses.unfree;
    sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
    platforms = [ "x86_64-linux" ];
    mainProgram = "saleae-logic2";
  };
}
