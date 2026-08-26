# GNU Radio layer matching RF-Swift-images/Dockerfiles/SDR/sdr_light.docker.
# The light image installs GNU Radio and common_sources_and_sinks
# (PentHertz gr-osmosdr); the extended OOT batches belong to sdr_full.
{ gnuradio, gr-osmosdr-penthertz }:

(gnuradio.override {
  extraPackages = [ gr-osmosdr-penthertz ];
}).overrideAttrs (old: {
  meta = old.meta // {
    mainProgram = "gnuradio-companion";
    description = "GNU Radio with RF Swift's light/common SDR source layer";
  };
})
