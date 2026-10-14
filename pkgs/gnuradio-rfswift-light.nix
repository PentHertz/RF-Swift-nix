# GNU Radio layer matching RF-Swift-images/Dockerfiles/SDR/sdr_light.docker.
# The light image installs GNU Radio, common_sources_and_sinks (PentHertz
# gr-osmosdr) and the dedicated HydraSDR OOT block (gr-hydrasdr); the extended
# OOT batches belong to sdr_full.
{ gnuradio, gr-osmosdr-penthertz, gr-hydrasdr, gr-bladeRF, gr-funcube, gnuradioBundle }:

let
  # gr-funcube belongs to the device layer (sdrsa_devices installs gr-funcube).
  extraPackages = [ gr-osmosdr-penthertz gr-hydrasdr gr-bladeRF gr-funcube ];
in
(gnuradio.override {
  inherit extraPackages;
  # qtpy for the Qt interface; examples_path for its example browser, which
  # reads a single one (see gnuradio-rfswift).
  extraPythonPackages = [ gnuradio.unwrapped.python.pkgs.qtpy ];
  extraMakeWrapperArgs = [
    "--set-default" "GR_CONF_GRC_EXAMPLES_PATH" "${placeholder "out"}/share/gnuradio/examples"
  ];
}).overrideAttrs (old: {
  buildCommand = old.buildCommand
    + gnuradioBundle.linkExamples extraPackages
    + gnuradioBundle.fixQtLocale;
  meta = old.meta // {
    mainProgram = "gnuradio-companion";
    description = "GNU Radio with RF Swift's light/common SDR source layer";
  };
})
