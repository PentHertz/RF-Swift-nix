# meshtastic_sdr: Meshtastic (LoRa mesh) receive/transmit GNU Radio flowgraphs
# plus the Python decoder/encoder scripts that sit behind them (crankylinuxuser,
# GitLab). Matches RF-Swift-images' meshtastic_sdr_soft_install. Upstream is not
# a package: we ship the .grc flowgraphs and sample IQ under share/ and expose
# the two scripts as commands. They need the `meshtastic` protobufs,
# cryptography and pyzmq, and GNU Radio's `pmt` module (the ZMQ messages they
# exchange with the flowgraph are PMTs) — so they run on GNU Radio's own Python
# with those packages added, and with GNU Radio's site-packages on the path.
{ lib, stdenvNoCC, fetchFromGitLab, gnuradio, makeWrapper }:

let
  gr = gnuradio.unwrapped;
  py = gr.python.withPackages (ps: with ps; [ meshtastic cryptography pyzmq ]);
in
stdenvNoCC.mkDerivation {
  pname = "meshtastic-sdr";
  version = "unstable-2025";

  src = fetchFromGitLab {
    owner = "crankylinuxuser";
    repo = "meshtastic_sdr";
    rev = "2ff1a68a42d8c9e4fee25a2d917fe38aaafbf0f1";
    hash = "sha256-tNlM11hrQewH+35wsMTERbh9rxFzg1g7yQ4ebNYgy0Q=";
  };

  nativeBuildInputs = [ makeWrapper ];
  dontBuild = true;

  installPhase = ''
    runHook preInstall
    share=$out/share/meshtastic-sdr
    mkdir -p $share $out/bin
    cp -r "gnuradio scripts" $share/flowgraphs
    cp -r "python scripts" $share/scripts
    cp -r "IQ data" $share/iq-samples
    cp README.md LICENSE $share/
    for s in RX TX; do
      lower=$(echo $s | tr 'A-Z' 'a-z')
      makeWrapper ${py}/bin/python3 $out/bin/meshtastic-gnuradio-$lower \
        --add-flags "$share/scripts/meshtastic_gnuradio_$s.py" \
        --prefix PYTHONPATH : "${gr}/${gr.python.sitePackages}"
    done
    runHook postInstall
  '';

  meta = {
    description = "Meshtastic LoRa mesh RX/TX GNU Radio flowgraphs and decoder/encoder scripts";
    homepage = "https://gitlab.com/crankylinuxuser/meshtastic_sdr";
    license = lib.licenses.gpl3Plus;
    platforms = lib.platforms.unix;
  };
}
