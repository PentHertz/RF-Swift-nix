# eaphammer: targeted evil-twin / RADIUS credential-capture framework (s0lst1c3).
# Its setup builds a bundled hostapd (hostapd-eaphammer) with rogue-AP patches;
# we compile that shared lib against the resurrected openssl_1_1 (built with the
# weak ciphers eaphammer's downgrade attacks need) and wrap the Python front-end.
{ lib, stdenv, fetchFromGitHub, makeWrapper, python3, pkg-config
, openssl_1_1, libnl, hcxtools, hcxdumptool }:

let
  pick = names: lib.filter (x: x != null) (map (n: python3.pkgs.${n} or null) names);
  pyEnv = python3.withPackages (ps: pick [
    "gevent" "tqdm" "pem" "pyopenssl" "scapy" "lxml" "beautifulsoup4"
    "flask-cors" "flask-socketio" "pywebcopy" "requests"
  ]);
in
stdenv.mkDerivation {
  pname = "eaphammer";
  version = "1.14.0-unstable";

  src = fetchFromGitHub {
    owner = "s0lst1c3";
    repo = "eaphammer";
    rev = "91e8956f640b13dbf58589430cf69b1541f9528b";
    hash = "sha256-LUqUSfM4U5adOk5yaM05wTE/47iKXiA46FzSP3peivw=";
  };

  nativeBuildInputs = [ makeWrapper pkg-config ];
  buildInputs = [ openssl_1_1 libnl ];

  # Nix's cc-wrapper injects these on every compile ON TOP of the Makefile's own
  # CFLAGS (so the config-derived -DCONFIG_* defines are preserved). openssl_1_1's
  # headers are found via buildInputs; libnl's live under an include/libnl3 subdir.
  env.NIX_CFLAGS_COMPILE = "-I${libnl.dev}/include/libnl3 -Wno-error -Wno-implicit-function-declaration -Wno-int-conversion";

  buildPhase = ''
    runHook preBuild
    pushd local/hostapd-eaphammer/hostapd
    cp defconfig .config
    # The bundled build expects an in-tree openssl at ../../openssl/local; point
    # it at the Nix openssl_1_1 instead of the broken relative rpath.
    substituteInPlace Makefile \
      --replace-fail "-Wl,-rpath=../../openssl/local/lib" "-L${openssl_1_1}/lib"
    make hostapd-eaphammer_lib -j$NIX_BUILD_CORES
    popd
    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall
    mkdir -p $out/share/eaphammer $out/bin
    cp -r . $out/share/eaphammer/
    makeWrapper ${pyEnv}/bin/python3 $out/bin/eaphammer \
      --add-flags "$out/share/eaphammer/eaphammer" \
      --chdir "$out/share/eaphammer" \
      --prefix PATH : "${lib.makeBinPath [ hcxtools hcxdumptool ]}" \
      --prefix LD_LIBRARY_PATH : "${openssl_1_1}/lib" \
      --prefix PYTHONPATH : "$out/share/eaphammer"
    runHook postInstall
  '';

  meta = {
    description = "Evil-twin / rogue-AP RADIUS credential-capture attack framework";
    homepage = "https://github.com/s0lst1c3/eaphammer";
    license = lib.licenses.gpl3Only;
    platforms = [ "x86_64-linux" ];
    mainProgram = "eaphammer";
  };
}
