# macstealer: WPA2 client isolation bypass / MAC-stealer research tool
# (vanhoefm). Builds the bundled wpa_supplicant (defconfig) and drives it from a
# Python script (macstealer.py + libwifi + wpaspy, all in-tree).
{ lib, stdenv, fetchFromGitHub, pkg-config, makeWrapper
, libnl, openssl, dbus, python3 }:

let
  pyEnv = python3.withPackages (ps: with ps; [ scapy ]);
in
stdenv.mkDerivation {
  pname = "macstealer";
  version = "1.1-unstable";

  src = fetchFromGitHub {
    owner = "vanhoefm";
    repo = "macstealer";
    rev = "83851791bc2657bd9f2f384d6b739956ab2c3ea8";
    hash = "sha256-mxJYRYOkRxSnMIVjPza25j80sa+lG1YDIvwApxOevqg=";
  };

  nativeBuildInputs = [ pkg-config makeWrapper ];
  buildInputs = [ libnl openssl dbus ];
  env.NIX_CFLAGS_COMPILE = "-Wno-error";

  buildPhase = ''
    runHook preBuild
    cp wpa_supplicant/defconfig wpa_supplicant/.config
    make -C wpa_supplicant -j$NIX_BUILD_CORES wpa_supplicant wpa_cli
    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall
    mkdir -p $out/bin $out/share/macstealer
    cp -rL research/* $out/share/macstealer/
    install -Dm755 wpa_supplicant/wpa_supplicant $out/share/macstealer/wpa_supplicant
    install -Dm755 wpa_supplicant/wpa_cli $out/share/macstealer/wpa_cli
    makeWrapper ${pyEnv}/bin/python3 $out/bin/macstealer \
      --add-flags "$out/share/macstealer/macstealer.py" \
      --chdir "$out/share/macstealer" \
      --prefix PATH : "$out/share/macstealer" \
      --prefix PYTHONPATH : "$out/share/macstealer"
    runHook postInstall
  '';

  meta = {
    description = "WPA2 client-isolation bypass / MAC-stealer attack tool";
    homepage = "https://github.com/vanhoefm/macstealer";
    license = lib.licenses.bsd3;
    platforms = lib.platforms.linux;
    mainProgram = "macstealer";
  };
}
