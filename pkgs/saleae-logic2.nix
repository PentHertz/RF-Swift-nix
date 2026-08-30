# Saleae Logic 2: the logic-analyzer GUI for Saleae devices (unfree binary
# download from downloads2.saleae.com, the same source RF Swift uses).
#
#   * Linux x86_64: the Type-2 AppImage, wrapped with appimageTools.
#   * aarch64-darwin: the official macOS arm64 zip, which ships a signed
#     "Saleae Logic.app" Electron bundle; install it under $out/Applications and
#     expose its executable on $PATH.
{ lib, stdenvNoCC, appimageTools, fetchurl, unzip }:

let
  pname = "saleae-logic2";
  version = "2.4.46";

  linuxSrc = fetchurl {
    url = "https://downloads2.saleae.com/logic2/Logic-${version}-linux-x64.AppImage";
    hash = "sha256-goMu0NMWZwHX9PffV6YgtyGiOIPgz+jy6OlaLmcg1vI=";
  };
  appimageContents = appimageTools.extractType2 {
    inherit pname version;
    src = linuxSrc;
  };

  linux = appimageTools.wrapType2 {
    inherit pname version;
    src = linuxSrc;
    extraInstallCommands = ''
      install -Dm444 ${appimageContents}/Logic.desktop -t $out/share/applications 2>/dev/null || true
      mkdir -p $out/bin && ln -sf $out/bin/${pname} $out/bin/logic2 2>/dev/null || true
      # Saleae's AppImage installs its udev rule at first run rather than
      # shipping it in a standard location, so `rfswift nix udev` would not find
      # it. Ship the rule (Saleae vendor 21a9, legacy Lakeview 0925) so the nix
      # engine installs it and the analyzer is reachable without root.
      install -Dm444 /dev/stdin $out/lib/udev/rules.d/99-SaleaeLogic.rules <<'RULES'
# Saleae Logic analyzers - installed by RF Swift (nix engine)
SUBSYSTEM=="usb", ATTR{idVendor}=="0925", MODE="0666", TAG+="uaccess"
SUBSYSTEM=="usb", ATTR{idVendor}=="21a9", MODE="0666", TAG+="uaccess"
RULES
    '';
    meta = commonMeta // { platforms = [ "x86_64-linux" ]; };
  };

  darwin = stdenvNoCC.mkDerivation {
    inherit pname version;
    src = fetchurl {
      url = "https://downloads2.saleae.com/logic2/Logic-${version}-macos-arm64.zip";
      hash = "sha256-lC0aSPHTdzRfvAaowA6JLkqMWWWcYupCqUFHHqO32Us=";
    };
    nativeBuildInputs = [ unzip ];
    # The zip's top-level entry is the .app itself, so unpack into a dir.
    sourceRoot = ".";
    installPhase = ''
      runHook preInstall
      mkdir -p "$out/Applications"
      cp -R "Saleae Logic.app" "$out/Applications/"
      # Expose the bundle's executable on PATH under both names. Electron resolves
      # its resources from the real path of the binary (inside the .app), so a
      # symlink into the bundle launches correctly.
      mkdir -p "$out/bin"
      ln -s "$out/Applications/Saleae Logic.app/Contents/MacOS/Logic" "$out/bin/${pname}"
      ln -s "$out/bin/${pname}" "$out/bin/logic2"
      runHook postInstall
    '';
    meta = commonMeta // { platforms = [ "aarch64-darwin" ]; };
  };

  commonMeta = {
    description = "Saleae Logic 2 logic-analyzer software";
    homepage = "https://www.saleae.com/";
    license = lib.licenses.unfree;
    sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
    mainProgram = "saleae-logic2";
  };
in
if stdenvNoCC.hostPlatform.isDarwin then darwin else linux
