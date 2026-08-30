# GNU Radio layer matching RF-Swift-images/Dockerfiles/SDR/sdr_light.docker.
# The light image installs GNU Radio, common_sources_and_sinks (PentHertz
# gr-osmosdr) and the dedicated HydraSDR OOT block (gr-hydrasdr); the extended
# OOT batches belong to sdr_full.
{ gnuradio, gr-osmosdr-penthertz, gr-hydrasdr, gr-bladeRF, gr-funcube }:

(gnuradio.override {
  # gr-funcube belongs to the device layer (sdrsa_devices installs gr-funcube).
  extraPackages = [ gr-osmosdr-penthertz gr-hydrasdr gr-bladeRF gr-funcube ];
}).overrideAttrs (old: {
  meta = old.meta // {
    mainProgram = "gnuradio-companion";
    description = "GNU Radio with RF Swift's light/common SDR source layer";
  };
})
