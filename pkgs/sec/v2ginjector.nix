# V2GInjector: Vehicle-to-Grid (V2G / ISO 15118) PowerLine penetration, monitor
# and injection tool (FlUxIuS). Python 3 + scapy with the HomePlugPWN layers, plus
# the Java V2Gdecoder service (EXI encode/decode) it drives.
{ lib, stdenv, python3Packages, fetchFromGitHub, fetchurl, makeWrapper, jre }:

let
  pyEnv = python3Packages.python.withPackages (ps: with ps; [ scapy colorama requests ]);
  v2gdecoderJar = fetchurl {
    url = "https://github.com/FlUxIuS/V2Gdecoder/releases/download/v1.2/V2Gdecoder.jar";
    hash = "sha256-jxGdv/E1F4rlm1nVp9qeBQz+ZcxQg5mze+O/lgstMlY=";
  };
in
stdenv.mkDerivation {
  pname = "v2ginjector";
  version = "unstable";

  src = fetchFromGitHub {
    owner = "FlUxIuS";
    repo = "V2GInjector";
    rev = "7d348560efa17084ab8af3543b63a2637824e836";
    fetchSubmodules = true;
    hash = "sha256-7KPeFImywJaFRFIhnlHOEM/50f9OSyyACwb4ndcJAYE=";
  };

  nativeBuildInputs = [ makeWrapper ];
  dontBuild = true;

  installPhase = ''
    runHook preInstall
    mkdir -p $out/share/v2ginjector $out/bin
    cp -r . $out/share/v2ginjector/
    # Bundle the prebuilt V2Gdecoder service and its schemas, as install.sh does.
    mkdir -p $out/share/v2ginjector/bin
    cp ${v2gdecoderJar} $out/share/v2ginjector/bin/V2Gdecoder.jar
    ln -sf thirdparty/V2Gdecoder/schemas $out/share/v2ginjector/schemas 2>/dev/null || true

    # Main tool: python V2GInjector, with HomePlugPWN layers on PYTHONPATH.
    makeWrapper ${pyEnv}/bin/python3 $out/bin/V2GInjector \
      --add-flags "$out/share/v2ginjector/V2GInjector" \
      --chdir "$out/share/v2ginjector" \
      --prefix PYTHONPATH : "$out/share/v2ginjector:$out/share/v2ginjector/thirdparty/HomePlugPWN"

    # Companion V2Gdecoder web service (java -jar ... -w).
    makeWrapper ${jre}/bin/java $out/bin/v2gdecoder \
      --add-flags "-jar $out/share/v2ginjector/bin/V2Gdecoder.jar"
    runHook postInstall
  '';

  meta = {
    description = "V2G / ISO 15118 PowerLine penetration, monitoring and injection tool";
    homepage = "https://github.com/FlUxIuS/V2GInjector";
    license = lib.licenses.gpl3Only;
    platforms = lib.platforms.linux;
    mainProgram = "V2GInjector";
  };
}
