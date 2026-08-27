# Proprietary vendor tools RF Swift downloads: SignalHound SDK + Spike, and the
# Harogic HTRA SDK. These are public downloads (signalhound.com, and the
# PentHertz GitHub mirror for Harogic), so `fetchurl` fetches them directly;
# allowUnfree (set in flake.nix) covers their licenses. No manual download.
#
# The hashes use lib.fakeHash and must be pinned on first build (they are large,
# so pin on a machine with disk headroom): `nix build .#pkg-signalhound-sdk`
# etc., then paste the reported hash.
{ pkgs }:

let
  inherit (pkgs) lib fetchurl stdenv autoPatchelfHook makeWrapper unzip
    libusb1 fftwFloat libftdi1 qt5 xcb-util-cursor libglvnd fontconfig freetype
    dbus zlib;
  inherit (pkgs.xorg) libX11 libxcb libXext libXrender;
  mkVendorBinary = pkgs.callPackage ./mkVendorBinary.nix { };
  ccLib = stdenv.cc.cc.lib;
in
rec {
  # Signal Hound device SDK: BB60/BB60D, SM, SP, SA and VSG APIs.
  # https://signalhound.com/sigdownloads/SDK/
  signalhound-sdk = stdenv.mkDerivation {
    pname = "signalhound-sdk";
    version = "08_26_26";
    src = fetchurl {
      url = "https://signalhound.com/sigdownloads/SDK/signal_hound_sdk_08_26_26.zip";
      hash = "sha256-G+ZwFjaXlNSzBJjNodunPeDrXKFocBq56LaoyfEeROY=";
    };
    nativeBuildInputs = [ unzip autoPatchelfHook ];
    buildInputs = [ libusb1 libftdi1 ccLib ];
    autoPatchelfIgnoreMissingDeps = true;
    dontBuild = true;
    # Extract only the Linux libraries and headers. The zip also ships Windows
    # DLLs and macOS dylibs we do not need (and unpacking them all is large).
    unpackPhase = ''
      runHook preUnpack
      unzip -q -o "$src" '*/lib/linux*/*' '*.h' -d src || \
        unzip -q -o "$src" '*linux*' '*.h' -d src
      runHook postUnpack
    '';
    installPhase = ''
      runHook preInstall
      mkdir -p $out/lib $out/include
      find src -type f -name 'lib*_api.so*' -exec cp -a {} $out/lib/ \;
      find src -type f -name '*.h' -exec cp -a {} $out/include/ \; 2>/dev/null || true
      runHook postInstall
    '';
    meta = {
      description = "Signal Hound device SDK (BB60/BB60D, SM200, SP145, SA and VSG60)";
      homepage = "https://signalhound.com/software/";
      license = lib.licenses.unfree;
      sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
      platforms = [ "x86_64-linux" ];
    };
  };

  # Signal Hound Spike: the spectrum-analyzer GUI. A Qt app with bundled libs.
  # https://signalhound.com/sigdownloads/Spike/
  signalhound-spike = stdenv.mkDerivation rec {
    pname = "signalhound-spike";
    version = "4_0_16";
    dirname = "Spike(Ubuntu22.04x64)_${version}";
    src = fetchurl {
      url = "https://signalhound.com/sigdownloads/Spike/${dirname}.zip";
      name = "signalhound-spike.zip";
      hash = "sha256-+Wx39z+W/pFdF0i2rpnKeoXNxWOPZNP6OVEeNdJK61k=";
    };
    nativeBuildInputs = [ unzip autoPatchelfHook makeWrapper ];
    buildInputs = [ libusb1 libftdi1 ccLib qt5.qtbase ];
    autoPatchelfIgnoreMissingDeps = true;
    dontWrapQtApps = true;
    dontBuild = true;
    unpackPhase = ''unzip -q "$src" -d src'';
    installPhase = ''
      runHook preInstall
      mkdir -p $out/opt/spike $out/bin
      cp -r "src/${dirname}"/* $out/opt/spike/
      chmod +x $out/opt/spike/bin/Spike
      # Spike finds its Qt plugins and bundled libs via these env vars.
      makeWrapper "$out/opt/spike/bin/Spike" "$out/bin/Spike" \
        --prefix LD_LIBRARY_PATH : "$out/opt/spike/lib" \
        --set QT_PLUGIN_PATH "$out/opt/spike/plugins"
      runHook postInstall
    '';
    meta = {
      description = "Signal Hound Spike spectrum analyzer software";
      homepage = "https://signalhound.com/spike/";
      license = lib.licenses.unfree;
      sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
      platforms = [ "x86_64-linux" ];
      mainProgram = "Spike";
    };
  };

  signalhound-vsg60 = stdenv.mkDerivation rec {
    pname = "signalhound-vsg60";
    version = "2_0_3";
    dirname = "VSG(Ubuntu22.04x64)_${version}";
    src = fetchurl {
      url = "https://signalhound.com/sigdownloads/VSG60/${dirname}.zip";
      name = "signalhound-vsg60.zip";
      hash = "sha256-0KeME74HOwTuGxUoK3voSqM71lKKSYhain0S+Mz1OWE=";
    };
    nativeBuildInputs = [ unzip autoPatchelfHook makeWrapper ];
    buildInputs = [ libusb1 libftdi1 ccLib qt5.qtbase ];
    autoPatchelfIgnoreMissingDeps = true;
    dontWrapQtApps = true;
    dontBuild = true;
    unpackPhase = ''unzip -q "$src" -d src'';
    installPhase = ''
      runHook preInstall
      mkdir -p $out/opt/vsg60 $out/bin
      cp -r "src/${dirname}"/* $out/opt/vsg60/
      chmod +x $out/opt/vsg60/bin/VSG
      makeWrapper "$out/opt/vsg60/bin/VSG" "$out/bin/vsg_signalhound" \
        --prefix LD_LIBRARY_PATH : "$out/opt/vsg60/lib" \
        --set QT_PLUGIN_PATH "$out/opt/vsg60/plugins"
      runHook postInstall
    '';
    meta = {
      description = "Signal Hound VSG60 vector signal generator control software";
      homepage = "https://signalhound.com/products/vsg60a/";
      license = lib.licenses.unfree;
      sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
      platforms = [ "x86_64-linux" ];
      mainProgram = "vsg_signalhound";
    };
  };

  # Harogic SAStudio4: the real-time spectrum-analyzer GUI for Harogic SA-series
  # devices. RF Swift downloads it from the same PentHertz mirror (see
  # RF-Swift-images/scripts/sa_devices.sh, harogic_sa_device_latest). SAStudio4
  # >= 4.4 (x86_64) ships as a flat portable bundle: bin/SAStudio4 runs directly
  # with the bundled SDK libs under lib/ on LD_LIBRARY_PATH.
  #
  # Large binary: pin the hash on first build (`nix build .#pkg-sastudio`).
  sastudio = stdenv.mkDerivation rec {
    pname = "sastudio";
    version = "4.4.55.48";
    tag = "v0.55.88";
    prog = "SAStudio4_${version}_amd64";
    src = fetchurl {
      url = "https://github.com/PentHertz/rfswift_harogic_install/releases/download/${tag}/${prog}.zip";
      hash = "sha256-qdwuH6o1o0TpHQxtSJvWwC4ObAA9XN/i/ibSCScalYA=";
    };
    nativeBuildInputs = [ unzip autoPatchelfHook makeWrapper ];
    buildInputs = [
      qt5.qtbase
      libusb1
      fftwFloat
      ccLib
      xcb-util-cursor
      libglvnd
      fontconfig
      freetype
      dbus
      zlib
      libX11
      libxcb
      libXext
      libXrender
    ];
    autoPatchelfIgnoreMissingDeps = true;
    dontWrapQtApps = true;
    dontBuild = true;
    unpackPhase = ''unzip -q "$src" -d src'';
    installPhase = ''
      runHook preInstall
      mkdir -p $out/opt/sastudio $out/bin
      # The zip may or may not contain a top-level dir depending on release; copy
      # whatever holds bin/SAStudio4.
      root=$(dirname "$(find src -name SAStudio4 -path '*/bin/*' | head -1)")
      cp -r "$root/../"* $out/opt/sastudio/
      chmod +x $out/opt/sastudio/bin/SAStudio4
      makeWrapper "$out/opt/sastudio/bin/SAStudio4" "$out/bin/sastudio" \
        --chdir "$out/opt/sastudio/bin" \
        --prefix LD_LIBRARY_PATH : "$out/opt/sastudio/lib" \
        --prefix QT_PLUGIN_PATH : "${qt5.qtbase.bin}/lib/qt-${qt5.qtbase.version}/plugins"
      runHook postInstall
    '';
    meta = {
      description = "Harogic SAStudio4 real-time spectrum analyzer GUI (SA-series)";
      homepage = "https://www.harogic.com/";
      license = lib.licenses.unfree;
      sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
      platforms = [ "x86_64-linux" ];
      mainProgram = "sastudio";
    };
  };

  # Harogic HTRA SDK (libhtra_api), from the public PentHertz mirror RF Swift uses.
  harogic-htra-sdk = mkVendorBinary {
    pname = "harogic-htra-sdk";
    version = "0.55.64";
    src = fetchurl {
      url = "https://github.com/PentHertz/rfswift_harogic_install/releases/download/v0.55.64/Install_HTRA_SDK.zip";
      hash = "sha256-rpJvNf9b9paLVmTlsf24GlCjekRJexYx4ygyyxUA7cY=";
    };
    libraries = [ libusb1 ccLib fftwFloat ];
    extraInstall = ''
      mkdir -p $out/lib $out/include
      find $out/opt/harogic-htra-sdk -name 'libhtra*.so*' -exec cp -a {} $out/lib/ \;
      find $out/opt/harogic-htra-sdk -name '*.h' -exec cp -a {} $out/include/ \; 2>/dev/null || true
    '';
    meta = {
      description = "Harogic HTRA SDK (SAxxxx real-time spectrum analyzers)";
      homepage = "https://www.harogic.com/";
    };
  };
}
