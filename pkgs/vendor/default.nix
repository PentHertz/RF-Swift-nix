# Proprietary vendor tools RF Swift downloads: SignalHound SDK + Spike, and the
# Harogic HTRA SDK. These are public downloads (signalhound.com, and the
# PentHertz GitHub mirror for Harogic), so `fetchurl` fetches them directly;
# allowUnfree (set in flake.nix) covers their licenses. No manual download.
#
# Version, URL, hash, and platform paths live in sources.json so maintainers can
# update commercial downloads without searching through build logic.
{ pkgs }:

let
  inherit (pkgs) lib fetchurl stdenv autoPatchelfHook fixDarwinDylibNames
    makeWrapper unzip
    libusb1 fftwFloat libftdi1 qt5 xcb-util-cursor libglvnd fontconfig freetype
    dbus zlib;
  # The xorg.* attribute set is deprecated in nixpkgs; the libraries live at
  # the top level now (evaluating the old names prints a warning).
  inherit (pkgs) libx11 libxcb libxext libxrender;
  mkVendorBinary = pkgs.callPackage ./mkVendorBinary.nix { };
  ccLib = stdenv.cc.cc.lib;
  sources = builtins.fromJSON (builtins.readFile ./sources.json);
  shSdk = sources."signalhound-sdk";
  spikeSource = sources."signalhound-spike";
  vsgSource = sources."signalhound-vsg60";
  sastudioSource = sources.sastudio;
  sastudioArtifact = sastudioSource.artifacts.${stdenv.hostPlatform.system}
    or sastudioSource.artifacts."x86_64-linux";
  sastudioSource_4_3_55_35 = sources."sastudio-4_3_55_35";
  sastudioArtifact_4_3_55_35 =
    sastudioSource_4_3_55_35.artifacts.${stdenv.hostPlatform.system}
      or sastudioSource_4_3_55_35.artifacts."x86_64-linux";
  htraSource = sources."harogic-htra-sdk";
  kcSource = sources."kc908-sdk";
  htraSource_0_55_64 = sources."harogic-htra-sdk-0_55_64";
  mkHarogicHtraSdk = source: mkVendorBinary {
    pname = "harogic-htra-sdk";
    version = source.version;
    src = fetchurl {
      inherit (source) url hash;
    };
    libraries = [ libusb1 ccLib fftwFloat ];
    extraInstall =
      let
        sdkArch = source.platformPaths.${stdenv.hostPlatform.system}
          or source.platformPaths."x86_64-linux";
      in
      ''
        mkdir -p $out/lib $out/include
        sdkLibRoot=$(find $out/opt/harogic-htra-sdk -type d -path '*/htraapi/lib' -print -quit)
        [ -n "$sdkLibRoot" ] || { echo "HTRA SDK library directory not found" >&2; exit 1; }
        # The archive contains multiple CPU architectures. Keep only the native
        # one so autoPatchelf never processes a foreign ELF binary. Older releases
        # have an additional Install_HTRA_SDK top-level directory.
        find "$sdkLibRoot" -mindepth 1 -maxdepth 1 \
          -type d ! -name '${sdkArch}' -exec rm -rf {} +
        cp -a "$sdkLibRoot/${sdkArch}"/libhtra*.so* $out/lib/
        for library in $out/lib/libhtra*.so.*; do
          [ -e "$library" ] || continue
          base=$(basename "$library")
          stem=''${base%%.so.*}
          ln -sf "$base" "$out/lib/$stem.so"
        done
        find $out/opt/harogic-htra-sdk -name '*.h' -exec cp -a {} $out/include/ \; 2>/dev/null || true
      '';
    meta = {
      description = "Harogic HTRA SDK ${source.version} (SAxxxx real-time spectrum analyzers)";
      homepage = "https://www.harogic.com/";
      platforms = [ "x86_64-linux" "aarch64-linux" ];
    };
  };
in
rec {
  # Signal Hound device SDK: BB60/BB60D, SM, SP, SA and VSG APIs.
  # https://signalhound.com/sigdownloads/SDK/
  signalhound-sdk = stdenv.mkDerivation {
    pname = "signalhound-sdk";
    version = shSdk.version;
    src = fetchurl {
      inherit (shSdk) url hash;
    };
    # ELF libs (Linux) need autoPatchelf; the macOS arm64 dylibs need their
    # install names fixed to absolute store paths so consumers (URH's ctypes
    # loader) resolve them.
    nativeBuildInputs = [ unzip ]
      ++ lib.optionals stdenv.hostPlatform.isLinux [ autoPatchelfHook ]
      ++ lib.optionals stdenv.hostPlatform.isDarwin [ fixDarwinDylibNames ];
    # The macOS dylibs link libusb too (their only non-system dependency), so it
    # must be in the closure on Darwin as well - see the install_name_tool rewrite
    # below.
    buildInputs = lib.optionals stdenv.hostPlatform.isLinux [ libusb1 libftdi1 ccLib ]
      ++ lib.optionals stdenv.hostPlatform.isDarwin [ libusb1 ];
    autoPatchelfIgnoreMissingDeps = true;
    dontBuild = true;
    # Extract the libraries for this platform, plus the (arch-independent) API
    # headers. The zip also ships Windows DLLs and the other platforms' libs,
    # which we skip (unpacking them all is large). The SDK ships macOS arm64
    # dylibs for the BB/SM/SP/VSG device series, so Darwin is a real target.
    unpackPhase = ''
      runHook preUnpack
    '' + (if stdenv.hostPlatform.isDarwin then ''
      unzip -q -o "$src" '*/lib/macos_arm/*' '*.h' -d src
    '' else if stdenv.hostPlatform.isAarch64 then ''
      unzip -q -o "$src" '*/lib/aarch64/*' '*.h' -d src
    '' else ''
      # x86_64 APIs use both linux_x64 (modern analyzers) and linux (legacy
      # TG/VSG25 APIs). Select Ubuntu builds where distributions are present.
      unzip -q -o "$src" '*/lib/linux_x64/Ubuntu 18.04/*' \
        '*/lib/linux/*' '*.h' -d src
    '') + ''
      runHook postUnpack
    '';
    installPhase = ''
      runHook preInstall
      mkdir -p $out/lib $out/include
    '' + (if stdenv.hostPlatform.isDarwin then ''
      find src -type f -name 'lib*_api*.dylib' -exec cp -a {} $out/lib/ \;
      # Provide the unversioned soname symlink linkers expect
      # (libbb_api.dylib -> libbb_api.5.0.11.dylib, etc.).
      for f in "$out"/lib/lib*_api.*.dylib; do
        [ -e "$f" ] || continue
        base=$(basename "$f"); stem=''${base%%.*}
        ln -sf "$base" "$out/lib/$stem.dylib"
        # Signal Hound's macOS dylibs hardcode a Homebrew libusb dependency
        # (/opt/homebrew/opt/libusb/lib/libusb-1.0.0.dylib) that does not exist
        # under Nix, so dlopen (URH's ctypes loader) fails with "Library not
        # loaded". Repoint it at the Nix libusb.
        install_name_tool -change \
          /opt/homebrew/opt/libusb/lib/libusb-1.0.0.dylib \
          ${libusb1}/lib/libusb-1.0.0.dylib "$f"
      done
    '' else ''
      find src -type f -name 'lib*_api.so*' -exec cp -a {} $out/lib/ \;
      for f in "$out"/lib/lib*_api.so.*; do
        [ -e "$f" ] || continue
        base=$(basename "$f")
        stem=''${base%%.so.*}
        version=''${base#*.so.}
        major=''${version%%.*}
        ln -sf "$base" "$out/lib/$stem.so.$major"
        ln -sf "$stem.so.$major" "$out/lib/$stem.so"
      done
    '') + ''
      find src -type f -name '*.h' -exec cp -a {} $out/include/ \; 2>/dev/null || true
      runHook postInstall
    '';
    meta = {
      description = "Signal Hound device SDK (BB60/BB60D, SM200, SP145, SA and VSG60)";
      homepage = "https://signalhound.com/software/";
      license = lib.licenses.unfree;
      sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
      platforms = [ "x86_64-linux" "aarch64-linux" "aarch64-darwin" ];
    };
  };

  # Signal Hound Spike: the spectrum-analyzer GUI. A Qt app with bundled libs.
  # https://signalhound.com/sigdownloads/Spike/
  signalhound-spike = stdenv.mkDerivation rec {
    pname = "signalhound-spike";
    version = spikeSource.version;
    dirname = spikeSource.platformPaths."x86_64-linux";
    src = fetchurl {
      inherit (spikeSource) url hash;
      name = "signalhound-spike.zip";
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
    version = vsgSource.version;
    dirname = vsgSource.platformPaths."x86_64-linux";
    src = fetchurl {
      inherit (vsgSource) url hash;
      name = "signalhound-vsg60.zip";
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
    version = sastudioSource.version;
    tag = sastudioSource.tag;
    prog = sastudioSource.platformPaths.${stdenv.hostPlatform.system}
      or sastudioSource.platformPaths."x86_64-linux";
    src = fetchurl {
      inherit (sastudioArtifact) url hash;
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
      libx11
      libxcb
      libxext
      libxrender
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
      platforms = [ "x86_64-linux" "aarch64-linux" ];
      mainProgram = "sastudio";
    };
  };

  # Retain the preceding application/SDK-compatible release as a selectable
  # fallback. overrideAttrs reuses the packaging and wrappers while replacing
  # only the version-specific archive.
  sastudio-4_3_55_35 = sastudio.overrideAttrs (_: {
    version = sastudioSource_4_3_55_35.version;
    tag = sastudioSource_4_3_55_35.tag;
    prog = sastudioSource_4_3_55_35.platformPaths.${stdenv.hostPlatform.system}
      or sastudioSource_4_3_55_35.platformPaths."x86_64-linux";
    src = fetchurl {
      inherit (sastudioArtifact_4_3_55_35) url hash;
    };
  });
  sastudio-4_4_55_48 = sastudio;

  # Keep supported Harogic releases side by side: an SDK update can regress on
  # particular customer hardware. The unversioned attribute is the recommended
  # default; users can deliberately pin either versioned attribute.
  harogic-htra-sdk-0_55_64 = mkHarogicHtraSdk htraSource_0_55_64;
  harogic-htra-sdk-0_55_88 = mkHarogicHtraSdk htraSource;
  harogic-htra-sdk = harogic-htra-sdk-0_55_88;

  # Deepace KC908 host libraries, from the PentHertz mirror RF Swift's images
  # use (RF-Swift-images/scripts/sa_devices.sh, kc908_sa_device): the FTDI
  # D3XX USB 3 library the SDR++ kcsdr_source module drives the radio through,
  # Deepace's libkcsdr + kcsdr.h (what gr-kc_sdr builds against) and the FTDI
  # udev rule, which `rfswift nix udev` installs on the host. The mirror only
  # ships x86_64 binaries, so the module is x86_64-linux only.
  kc908-sdk = stdenv.mkDerivation {
    pname = "kc908-sdk";
    version = kcSource.version;
    src = fetchurl {
      inherit (kcSource) url hash;
    };
    nativeBuildInputs = [ unzip autoPatchelfHook ];
    buildInputs = [ libusb1 ccLib ];
    dontBuild = true;
    # The zip also carries a GNU Radio OOT module tree; only lib/ is needed.
    unpackPhase = ''
      runHook preUnpack
      unzip -q -o "$src" 'KC908-GNURadio/lib/*' -d src
      runHook postUnpack
    '';
    installPhase = ''
      runHook preInstall
      mkdir -p $out/lib/udev/rules.d $out/include
      lib=src/KC908-GNURadio/lib
      install -m644 $lib/linux/libftd3xx.so $out/lib/libftd3xx.so
      # libftd3xx.so carries no SONAME; provide the versioned name FTDI's own
      # package installs so anything looking for it resolves too.
      ln -s libftd3xx.so $out/lib/libftd3xx.so.0.5.21
      install -m644 $lib/linux/ftd3xx.h $out/include/ftd3xx.h
      install -m644 $lib/libkcsdr.so $out/lib/libkcsdr.so
      install -m644 $lib/kcsdr.h $out/include/kcsdr.h
      install -m644 $lib/linux/51-ftd3xx.rules $out/lib/udev/rules.d/51-ftd3xx.rules
      runHook postInstall
    '';
    meta = {
      description = "Deepace KC908 host libraries (FTDI D3XX, libkcsdr) and udev rule";
      homepage = "https://www.deepace.net/";
      license = lib.licenses.unfree;
      sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
      platforms = [ "x86_64-linux" ];
    };
  };
}
