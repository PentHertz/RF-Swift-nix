# Burp Suite (PortSwigger's unified desktop jar), pinned to the release RF
# Swift's images install (network_common.sh: burpsuite_community_install).
# nixpkgs' recipe bakes its version and jar hash into a `let`, so it cannot be
# moved forward with an override; this is that recipe with RF Swift's pin.
# Without a Pro license key the jar runs as the Community edition.
{ config
, lib
, buildFHSEnv
, fetchurl
, jdk
, makeDesktopItem
, unzip
  # Either "community" or "pro" (only selects the icon)
, iconName ? "community"
, licenseAccepted ? config.burpsuite.accept_license or false
}:

assert lib.assertMsg (iconName == "pro" || iconName == "community")
  "iconName has to be either pro or community";

let
  pname = "burpsuite";
  version = "2026.9.1";

  src = fetchurl {
    name = "burpsuite.jar";
    urls = [
      "https://portswigger-cdn.net/burp/releases/download?product=desktop&version=${version}&type=Jar"
      "https://portswigger.net/burp/releases/download?product=desktop&version=${version}&type=Jar"
    ];
    hash = "sha256-8FgPLvZuZ5VG9TYyd9jBynLNy7v8PcR5HEbPLAUIEZo=";
  };

  description = "Integrated platform for performing security testing of web applications";

  desktopItem = makeDesktopItem {
    name = pname;
    exec = pname;
    icon = pname;
    desktopName = "Burp Suite Desktop";
    comment = description;
    categories = [ "Development" "Security" "System" ];
  };
in
buildFHSEnv {
  inherit pname version;

  runScript =
    "${lib.getExe jdk} -jar ${src} --suppress-jre-check --disable-check-for-updates-dialog --disable-auto-update"
    + lib.optionalString licenseAccepted " --i-accept-the-license-agreement";

  targetPkgs = pkgs: with pkgs; [
    alsa-lib
    at-spi2-core
    cairo
    cups
    dbus
    expat
    glib
    gtk3
    gtk3-x11
    jython
    libcanberra-gtk3
    libdrm
    udev
    libxkbcommon
    libgbm
    libglvnd
    nspr
    nss
    pango
    libx11
    libxcb
    libxcomposite
    libxdamage
    libxext
    libxfixes
    libxrandr
  ];

  extraInstallCommands = ''
    mkdir -p "$out/share/icons/hicolor/64x64/apps"
    ${lib.getBin unzip}/bin/unzip -p ${src} resources/Media/icon64${iconName}.png > "$out/share/icons/hicolor/64x64/apps/burpsuite.png"
    cp -r ${desktopItem}/share/applications $out/share
  '';

  meta = {
    inherit description;
    homepage = "https://portswigger.net/burp/";
    changelog = "https://portswigger.net/burp/releases/professional-community-${lib.replaceStrings [ "." ] [ "-" ] version}";
    sourceProvenance = with lib.sourceTypes; [ binaryBytecode ];
    license = lib.licenses.unfree;
    # buildFHSEnv is Linux-only.
    platforms = lib.intersectLists jdk.meta.platforms lib.platforms.linux;
    mainProgram = "burpsuite";
  };
}
