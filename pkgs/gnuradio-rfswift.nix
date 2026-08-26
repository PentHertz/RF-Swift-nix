# GNU Radio bundled with RF Swift's OOT modules, so the blocks actually show up
# in gnuradio-companion. Listing OOT packages next to `gnuradio` in an
# environment does NOT make GRC see them; they must be in gnuradio's own prefix,
# which is what `gnuradio.override { extraPackages = ... }` does.
{ gnuradio, gnuradioPackages, gr-osmosdr-penthertz, gr-rds, gr-iridium
, gr-satellites, gr-gsm, gr-ais, gr-limesdr, gr-tempest, gr-dab
, gr-foo, gr-adsb, gr-paint, gr-dect2, gr-nfc, gr-air-modes
, gr-ieee802-11, gr-ieee802-15-4
, gr-lora, gr-inspector, gr-uaslink, gr-X10, gr-gfdm, gr-aaronia_rtsa, gr-aistx
, gr-dvbs2, gr-ieee802-11ah, gr-ieee80211, gr-droneid, gr-keyfob, gr-radar
, gr-nordic, gr-pdu_utils, gr-timing_utils, gr-sandia_utils, gr-fhss_utils
, gr-zwave_poore, gr-mixalot, gr-reveng, gr-j2497, gr-m17
, gr-grnet, gr-aoa, gr-correctiq, gr-dsd, gr-nrsc5, gr-ntsc-rc, gr-mer, gr-flarm
, gr-guiextra, gr-rftap, gr-radio_astro, gr-cessb }:

(gnuradio.override {
  extraPackages = [
    gr-osmosdr-penthertz
    gnuradioPackages.lora_sdr
    gnuradioPackages.gr-difi
    gnuradioPackages.fosphor
    # Source-built OOT modules (pkgs/oot/), the default set RF Swift ships.
    gr-rds gr-iridium gr-satellites gr-gsm gr-ais gr-limesdr gr-tempest gr-dab
    gr-foo gr-adsb gr-paint gr-dect2 gr-nfc gr-air-modes
    gr-ieee802-11 gr-ieee802-15-4
    gr-lora gr-inspector gr-uaslink gr-X10 gr-gfdm gr-aaronia_rtsa gr-aistx
    gr-dvbs2 gr-ieee802-11ah gr-ieee80211 gr-droneid gr-keyfob gr-radar
    gr-nordic gr-pdu_utils gr-timing_utils gr-sandia_utils gr-fhss_utils
    gr-zwave_poore gr-mixalot gr-reveng gr-j2497 gr-m17
    gr-grnet gr-aoa gr-correctiq gr-dsd gr-nrsc5 gr-ntsc-rc gr-mer gr-flarm
    gr-guiextra gr-rftap gr-radio_astro gr-cessb
  ];
}).overrideAttrs (old: {
  # nixpkgs currently selects `gnuradio-config-info`, which is useful for
  # diagnostics but is not the command users expect to launch in a lazy RF
  # Swift environment. This entry point also realizes the complete OOT bundle.
  meta = old.meta // { mainProgram = "gnuradio-companion"; };
})
