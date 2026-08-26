# tetra-kit: TETRA downlink decoder/recorder (larryth, GitLab). Plain Makefiles;
# GNU Radio is runtime-only (the pi4dqpsk_rx.grc flowgraph feeds bits over UDP).
{ lib, stdenv, fetchFromGitLab, rapidjson, zlib, ncurses, sox, makeWrapper }:

stdenv.mkDerivation {
  pname = "tetra-kit";
  version = "1.7-unstable";

  src = fetchFromGitLab {
    owner = "larryth";
    repo = "tetra-kit";
    rev = "master";
    hash = "sha256-onrPX0iO2TNg6Fi3WboeKfgOOlW1YYv5SzC9d95/n9c=";
  };

  nativeBuildInputs = [ makeWrapper ];
  buildInputs = [ rapidjson zlib ncurses ];

  env.NIX_CFLAGS_COMPILE = "-Wno-error";

  buildPhase = ''
    runHook preBuild
    make -C decoder
    make -C recorder
    make -C codec
    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall
    mkdir -p $out/bin $out/share/tetra-kit
    install -Dm755 decoder/decoder $out/bin/tetra-decoder
    install -Dm755 recorder/recorder $out/bin/tetra-recorder
    for b in codec/cdecoder codec/sdecoder codec/ccoder codec/scoder; do
      [ -f "$b" ] && install -Dm755 "$b" "$out/bin/tetra-$(basename $b)"
    done
    # Ship the runtime PHY flowgraph and helper scripts.
    cp -r phy $out/share/tetra-kit/ 2>/dev/null || true
    find . -maxdepth 2 -name '*2wav.sh' -exec cp {} $out/share/tetra-kit/ \; 2>/dev/null || true
    runHook postInstall
  '';

  meta = {
    description = "TETRA downlink decoder/recorder kit (PI/4-DQPSK receiver + decoder)";
    homepage = "https://gitlab.com/larryth/tetra-kit";
    license = lib.licenses.gpl3Plus;
    platforms = lib.platforms.linux;
  };
}
