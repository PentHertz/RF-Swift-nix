# wpa_sycophant (sensepost/wpa_sycophant): a WPA-Enterprise auditing tool used
# together with hostapd-mana's enable_sycophant option. It is a modified
# wpa_supplicant (2.7-devel) plus a launcher script wpa_sycophant.sh.
# Matches RF-Swift-images' wpa_sycophant_soft_install (`make -C wpa_supplicant`,
# then a `wpa_sycophant` wrapper running ./wpa_sycophant.sh from the repo dir).
#
# The bundled wpa_supplicant (.config enables nl80211 + libnl 3.2) builds fine
# against the current OpenSSL, so we do not need openssl_1_1 here. The launcher
# runs ./wpa_supplicant/wpa_supplicant and then dhclient (ISC dhcp) to pick up an
# address; we fix the relative supplicant path to the installed binary. dhclient
# is not bundled: ISC dhcp was dropped from nixpkgs, so that optional post-connect
# DHCP step only runs if the user has a dhclient on PATH - the relay itself works
# without it.
{ lib, stdenv, fetchFromGitHub, makeWrapper, pkg-config
, libnl, openssl, dbus, readline }:

stdenv.mkDerivation {
  pname = "wpa_sycophant";
  version = "unstable-2023-07-05";

  src = fetchFromGitHub {
    owner = "sensepost";
    repo = "wpa_sycophant";
    rev = "36b5bff94f772489c10b4d02fc604393bbfe68e2";
    hash = "sha256-i9JIaDyu2jsJzwaZpuJkST1zCaop6bB0mgIf+E4CmHo=";
  };

  nativeBuildInputs = [ makeWrapper pkg-config ];
  buildInputs = [ libnl openssl dbus readline ];

  # libnl headers live under include/libnl3; relax the warnings this old tree
  # trips on modern gcc.
  env.NIX_CFLAGS_COMPILE = "-I${libnl.dev}/include/libnl3 -Wno-error -Wno-implicit-function-declaration -Wno-int-conversion";

  buildPhase = ''
    runHook preBuild
    make -C wpa_supplicant -j$NIX_BUILD_CORES CONFIG_NO_GITVER=y
    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall
    mkdir -p $out/bin $out/libexec/wpa_sycophant
    install -Dm755 wpa_supplicant/wpa_supplicant \
      $out/libexec/wpa_sycophant/wpa_supplicant/wpa_supplicant
    install -Dm644 wpa_sycophant_example.conf \
      $out/share/wpa_sycophant/wpa_sycophant_example.conf

    # The launcher cd's nowhere and uses ./wpa_supplicant/wpa_supplicant; point
    # it at the installed binary so it works from any directory.
    install -Dm755 wpa_sycophant.sh $out/libexec/wpa_sycophant/wpa_sycophant.sh
    substituteInPlace $out/libexec/wpa_sycophant/wpa_sycophant.sh \
      --replace-fail './wpa_supplicant/wpa_supplicant' \
        "$out/libexec/wpa_sycophant/wpa_supplicant/wpa_supplicant"
    patchShebangs $out/libexec/wpa_sycophant/wpa_sycophant.sh

    makeWrapper $out/libexec/wpa_sycophant/wpa_sycophant.sh $out/bin/wpa_sycophant
    runHook postInstall
  '';

  meta = {
    description = "WPA-Enterprise EAP relay client (pairs with hostapd-mana enable_sycophant)";
    homepage = "https://github.com/sensepost/wpa_sycophant";
    license = lib.licenses.bsd3; # wpa_supplicant's BSD license
    platforms = lib.platforms.linux;
    mainProgram = "wpa_sycophant";
  };
}
