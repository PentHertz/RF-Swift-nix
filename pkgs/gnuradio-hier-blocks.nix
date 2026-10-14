# GNU Radio hierarchical blocks that OOT example flowgraphs are built on (the
# 802.11, HaLow and 802.15.4 PHYs, gr-tempest's helpers, gr-gfdm's receivers,
# ...). They ship only as .grc sources: GRC compiles one into ~/.grc_gnuradio
# when a user opens it, and RF-Swift-images runs grcc on some of them at image
# build time. Do it here for all of them, with a GNU Radio that holds the
# modules they use (and those modules' Python dependencies), and
# install each block (.block.yml) and its Python where the bundle's GNU Radio
# finds them, so the examples open and run out of the box.
{ lib, stdenv, runCommand, gnuradio
, gr-foo, gr-ieee802-11, gr-ieee802-11ah, gr-ieee802-15-4, gr-ieee80211
, gr-tempest, gr-gfdm, gr-ais, gr-flarm, gr-funcube }:

let
  # { pkg; grc (path in pkg.src); needs (other modules its blocks use) }
  sources = [
    { pkg = gr-ieee802-11; grc = "examples/wifi_phy_hier.grc"; needs = [ gr-foo ]; }
    { pkg = gr-ieee802-11ah; grc = "examples/halow_phy_hier.grc"; needs = [ gr-foo ]; }
    { pkg = gr-ieee802-15-4; grc = "examples/ieee802_15_4_OQPSK_PHY.grc"; needs = [ gr-foo ]; }
    { pkg = gr-ieee802-15-4; grc = "examples/ieee802_15_4_CSS_PHY.grc"; needs = [ gr-foo ]; }
    { pkg = gr-ieee80211; grc = "examples/presiso.grc"; needs = [ ]; }
    { pkg = gr-tempest; grc = "examples/FFT_autocorrelate.grc"; needs = [ ]; }
    { pkg = gr-tempest; grc = "examples/FFT_crosscorrelate.grc"; needs = [ ]; }
    { pkg = gr-tempest; grc = "examples/Keep_1_in_N_frames.grc"; needs = [ ]; }
    { pkg = gr-gfdm; grc = "examples/hier_gfdm_receiver.grc"; needs = [ ]; }
    { pkg = gr-gfdm; grc = "examples/hier_gfdm_receiver_stream.grc"; needs = [ ]; }
    { pkg = gr-gfdm; grc = "examples/hier_gfdm_receiver_tagged.grc"; needs = [ ]; }
    { pkg = gr-gfdm; grc = "examples/hier_gfdm_transmitter.grc"; needs = [ ]; }
    # Not hier_gfdm_fastsync.grc: upstream leaves its pads unconnected, so it
    # does not compile (nor do gfdm_fast_sync_demo / gfdm_ota_demo, built on it).
    { pkg = gr-ais; grc = "apps/ais_demod.grc"; needs = [ ]; }
    { pkg = gr-flarm; grc = "apps/flarm_channel_rx.grc"; needs = [ ]; }
    { pkg = gr-funcube; grc = "examples/decodeapt.grc"; needs = [ ]; }
    # Not gr-gsm's hier_blocks/: the module ships gsm_input as a regular block.
  ];
  available = p:
    let ok = builtins.tryEval (lib.meta.availableOn stdenv.hostPlatform p);
    in ok.success && ok.value;
  used = builtins.filter (s: lib.all available ([ s.pkg ] ++ s.needs)) sources;
  modules = lib.unique (lib.concatMap (s: [ s.pkg ] ++ s.needs) used);
  grWith = gnuradio.override { extraPackages = modules; };
  python = gnuradio.unwrapped.python;
in
runCommand "gnuradio-rfswift-hier-blocks" {
  nativeBuildInputs = [ grWith ];
  # Lets the gnuradio-rfswift bundle drop it when nothing applies on a host.
  passthru.blockCount = builtins.length used;
} ''
  export HOME=$TMPDIR GRC_HIER_PATH=$TMPDIR/hier
  mkdir -p "$GRC_HIER_PATH"
  ${lib.concatMapStrings (s: ''
    echo "grcc ${s.pkg.pname}: ${s.grc}"
    grcc -o "$GRC_HIER_PATH" "${s.pkg.src}/${s.grc}"
  '') used}
  # A module may already ship the compiled block's .block.yml, but not the
  # Python it imports (gr-ais: ais_rx_core). Keep the module's, add the Python.
  for m in ${toString modules}; do
    for y in "$GRC_HIER_PATH"/*.block.yml; do
      if [ -e "$m/share/gnuradio/grc/blocks/''${y##*/}" ]; then rm "$y"; fi
    done
  done
  mkdir -p "$out/${python.sitePackages}" "$out/share/gnuradio/grc/blocks"
  mv "$GRC_HIER_PATH"/*.py "$out/${python.sitePackages}/"
  mv "$GRC_HIER_PATH"/*.block.yml "$out/share/gnuradio/grc/blocks/"
''
