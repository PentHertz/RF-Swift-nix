# qthid: Qt controller GUI for the FUNcube Dongle (csete); the
# qthid-fcd-controller package of the sdrsa_devices image, built from source.
# Plain qmake project bundling its own hidapi backend: hid-libusb.c on Linux
# (libusb via pkg-config), hidmac.c on macOS (IOKit), so only Qt and, on Linux,
# libusb are needed. The project has no install target.
{ lib, stdenv, fetchFromGitHub, qt5, pkg-config, libusb1 }:

stdenv.mkDerivation {
  pname = "qthid";
  version = "unstable-2020";

  src = fetchFromGitHub {
    owner = "csete";
    repo = "qthid";
    rev = "53b17ac1e84613be79fbe59cb0071707ad8143af";
    hash = "sha256-oQdoxZLvKjKK7dAM96BQfHWKeuqaH7MbosaQma2iQDM=";
  };

  # One Qt4-era include survives (QApplication moved to QtWidgets in Qt 5). On
  # macOS the project links the system frameworks by absolute /System path,
  # which the Nix sandbox does not expose; use -framework so the SDK resolves them.
  postPatch = ''
    substituteInPlace main.cpp --replace-fail "<QtGui/QApplication>" "<QApplication>"
  '' + lib.optionalString stdenv.hostPlatform.isDarwin ''
    substituteInPlace qthid.pro \
      --replace-fail "/System/Library/Frameworks/CoreFoundation.framework/CoreFoundation" "-framework CoreFoundation" \
      --replace-fail "/System/Library/Frameworks/IOKit.framework/Versions/A/IOKit" "-framework IOKit"
  '';

  nativeBuildInputs = [ qt5.qmake qt5.wrapQtAppsHook ]
    ++ lib.optionals stdenv.hostPlatform.isLinux [ pkg-config ];
  buildInputs = [ qt5.qtbase ]
    ++ lib.optionals stdenv.hostPlatform.isLinux [ libusb1 ];

  # On Darwin qmake builds a `Qthid.app` bundle (TARGET = Qthid in qthid.pro).
  # The hook's automatic pass walks bin/ and Applications/ while it renames the
  # binaries it wraps, so a bin/ link into the bundle got wrapped twice and the
  # pass crashed nondeterministically (segfault 139 under load). Wrap the bundle
  # binary once, explicitly, then link it into bin/.
  dontWrapQtApps = stdenv.hostPlatform.isDarwin;

  installPhase = ''
    runHook preInstall
    mkdir -p $out/bin
  '' + (if stdenv.hostPlatform.isDarwin then ''
    mkdir -p $out/Applications
    cp -r Qthid.app $out/Applications/
  '' else ''
    install -Dm755 qthid $out/bin/qthid
  '') + ''
    runHook postInstall
  '';

  postFixup = lib.optionalString stdenv.hostPlatform.isDarwin ''
    wrapQtApp $out/Applications/Qthid.app/Contents/MacOS/Qthid
    ln -s ../Applications/Qthid.app/Contents/MacOS/Qthid $out/bin/qthid
  '';

  meta = {
    description = "FUNcube Dongle controller (Qt)";
    homepage = "https://github.com/csete/qthid";
    license = lib.licenses.gpl3Plus;
    mainProgram = "qthid";
    platforms = lib.platforms.unix;
  };
}
