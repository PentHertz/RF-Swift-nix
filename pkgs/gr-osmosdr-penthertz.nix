# gr-osmosdr, PentHertz "resolute" fork: adds a native HydraSDR RFOne backend.
# Built against RF Swift's soapysdr-with-plugins (pkgs/default.nix) so its
# Soapy backend also reaches RFNM, XTRX, LiteX M2SDR and uSDR; gqrx and every
# GNU Radio flowgraph using osmosdr blocks inherit both.
{ lib, fetchFromGitHub, gnuradioPackages, libhydrasdr, soapysdr-with-plugins }:

(gnuradioPackages.osmosdr.override { inherit soapysdr-with-plugins; }).overrideAttrs (old: {
  pname = "gr-osmosdr-penthertz";
  version = "unstable-penthertz";
  src = fetchFromGitHub {
    owner = "PentHertz";
    repo = "gr-osmosdr_resolute";
    rev = "206fff787dcac512399189915c0f7f1c0f020223";
    hash = "sha256-lVaVQ3hNf7UhbmXsw9FQSwfVXrTeKa5bYSRxMxJFRmw=";
  };
  buildInputs = (old.buildInputs or [ ]) ++ [ libhydrasdr ];
  # The Soapy backend's set_if_gain/set_bb_gain take front()/back() of the
  # channel's gain-element list without checking it is non-empty. A device
  # with no gain elements (SoapyAudio, which osmosdr falls back to on a Mac
  # with no SDR plugged in) makes that undefined behaviour; nixpkgs' hardened
  # libc++ traps on it (SIGTRAP), killing the flowgraph as soon as GRC's
  # generated code sets the IF gain. Leave the gain alone when there is none.
  postPatch = (old.postPatch or "") + ''
    for f in lib/soapy/soapy_source_c.cc lib/soapy/soapy_sink_c.cc; do
      substituteInPlace $f \
        --replace-fail "const std::string name = this->get_gain_names(chan).front();" \
          "const std::vector<std::string> names = this->get_gain_names(chan); if (names.empty()) return 0.0; const std::string name = names.front();" \
        --replace-fail "const std::string name = this->get_gain_names(chan).back();" \
          "const std::vector<std::string> names = this->get_gain_names(chan); if (names.empty()) return 0.0; const std::string name = names.back();"
    done
  '';
  meta = (old.meta or { }) // {
    description = "gr-osmosdr (PentHertz resolute fork) source/sink blocks for GNU Radio";
    homepage = "https://github.com/PentHertz/gr-osmosdr_resolute";
  };
})
