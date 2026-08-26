# dragonslayer: WPA3 / EAP-pwd downgrade & side-channel attack tools (vanhoefm).
# Ships a patched hostapd + wpa_supplicant (built here against openssl_1_1), driven
# by the dragonslayer-server.sh / dragonslayer-client.sh scripts.
{ lib, stdenv, fetchFromGitHub, makeWrapper, pkg-config, bash
, openssl_1_1, libnl, dbus }:

stdenv.mkDerivation {
  pname = "dragonslayer";
  version = "unstable";

  src = fetchFromGitHub {
    owner = "vanhoefm";
    repo = "dragonslayer";
    rev = "e52180f5367e03cdc6681db81ae2e5fcfe50e4cf";
    hash = "sha256-JgKGFI9nrdQAR2HS9WNDPc7n+W0vZEhS+fJp3+kvx1U=";
  };

  nativeBuildInputs = [ makeWrapper pkg-config ];
  buildInputs = [ openssl_1_1 libnl dbus ];
  env.NIX_CFLAGS_COMPILE = "-I${libnl.dev}/include/libnl3 -I${dbus.dev}/include/dbus-1.0 -I${dbus.lib}/lib/dbus-1.0/include -Wno-error -Wno-incompatible-pointer-types -Wno-implicit-function-declaration -Wno-implicit-int -Wno-int-conversion";

  buildPhase = ''
    runHook preBuild
    cp hostapd/defconfig hostapd/.config
    echo "CONFIG_LIBNL32=y" >> hostapd/.config
    make -C hostapd -j$NIX_BUILD_CORES hostapd hostapd_cli
    cp wpa_supplicant/defconfig wpa_supplicant/.config
    echo "CONFIG_LIBNL32=y" >> wpa_supplicant/.config
    make -C wpa_supplicant -j$NIX_BUILD_CORES wpa_supplicant wpa_cli
    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall
    # Preserve the tree layout the scripts expect (../hostapd, ../wpa_supplicant).
    mkdir -p $out/share/dragonslayer/{hostapd,wpa_supplicant} $out/bin
    install -Dm755 hostapd/hostapd $out/share/dragonslayer/hostapd/hostapd
    install -Dm755 wpa_supplicant/wpa_supplicant $out/share/dragonslayer/wpa_supplicant/wpa_supplicant
    cp -rL dragonslayer/* $out/share/dragonslayer/dragonslayer/ 2>/dev/null || cp -rL dragonslayer $out/share/dragonslayer/
    for s in dragonslayer-server dragonslayer-client; do
      f=$out/share/dragonslayer/dragonslayer/$s.sh
      [ -f "$f" ] && chmod +x "$f" && makeWrapper ${bash}/bin/bash $out/bin/$s \
        --add-flags "$f" --chdir "$out/share/dragonslayer/dragonslayer"
    done
    runHook postInstall
  '';

  meta = {
    description = "WPA3 / EAP-pwd Dragonblood downgrade and side-channel attack tools";
    homepage = "https://github.com/vanhoefm/dragonslayer";
    license = lib.licenses.bsd3;
    platforms = [ "x86_64-linux" ];
  };
}
