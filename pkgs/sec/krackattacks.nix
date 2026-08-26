# krackattacks-scripts: Mathy Vanhoef's KRACK (key-reinstallation) test scripts.
# They drive a patched hostapd + wpa_supplicant (built here against openssl_1_1)
# from Python (krack-test-client.py / krack-ft-test.py + bundled libwifi/wpaspy).
{ lib, stdenv, fetchFromGitHub, makeWrapper, pkg-config, python3
, openssl_1_1, libnl }:

let
  pyEnv = python3.withPackages (ps: with ps; [ scapy ]);
in
stdenv.mkDerivation {
  pname = "krackattacks-scripts";
  version = "unstable";

  src = fetchFromGitHub {
    owner = "vanhoefm";
    repo = "krackattacks-scripts";
    rev = "2dc8012adc18ee1c567b428e095837d0bc0793fd";
    hash = "sha256-8LRZUCJq5DTpMFmtvy+XMvO9JjMW6NHwlsoV3xfH33U=";
  };

  nativeBuildInputs = [ makeWrapper pkg-config ];
  buildInputs = [ openssl_1_1 libnl ];
  # This is 2017-era hostapd; gcc-14+ promotes several old-C warnings to errors by
  # default (incompatible-pointer-types from libnl's nl_sock vs hostapd's nl_handle,
  # implicit decls, int conversions), so demote them back to warnings.
  env.NIX_CFLAGS_COMPILE = "-I${libnl.dev}/include/libnl3 -Wno-error -Wno-incompatible-pointer-types -Wno-implicit-function-declaration -Wno-implicit-int -Wno-int-conversion";

  buildPhase = ''
    runHook preBuild
    cp hostapd/defconfig hostapd/.config
    make -C hostapd -j$NIX_BUILD_CORES hostapd hostapd_cli
    cp wpa_supplicant/defconfig wpa_supplicant/.config
    # Its defconfig links the old libnl-1 (-lnl); use libnl-3 like hostapd does.
    echo "CONFIG_LIBNL32=y" >> wpa_supplicant/.config
    make -C wpa_supplicant -j$NIX_BUILD_CORES wpa_supplicant wpa_cli
    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall
    mkdir -p $out/bin $out/share/krackattacks
    install -Dm755 hostapd/hostapd $out/share/krackattacks/hostapd
    install -Dm755 wpa_supplicant/wpa_supplicant $out/share/krackattacks/wpa_supplicant
    cp -rL krackattack/* $out/share/krackattacks/
    for s in krack-test-client krack-ft-test; do
      makeWrapper ${pyEnv}/bin/python3 $out/bin/$s \
        --add-flags "$out/share/krackattacks/$s.py" \
        --chdir "$out/share/krackattacks" \
        --prefix PATH : "$out/share/krackattacks" \
        --prefix PYTHONPATH : "$out/share/krackattacks"
    done
    runHook postInstall
  '';

  meta = {
    description = "KRACK (Key Reinstallation Attack) test scripts for WPA2";
    homepage = "https://github.com/vanhoefm/krackattacks-scripts";
    license = lib.licenses.bsd3;
    platforms = [ "x86_64-linux" ];
    mainProgram = "krack-test-client";
  };
}
