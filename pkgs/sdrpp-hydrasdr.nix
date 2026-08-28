# SDR++ (SDRPlusPlus), HydraSDR fork. Overrides the nixpkgs sdrpp source so we
# reuse its full set of source/sink build flags and dependencies.
{ lib, stdenv, fetchFromGitHub, sdrpp, libhydrasdr, libjack2 }:

sdrpp.overrideAttrs (old: {
  pname = "sdrpp-hydrasdr";
  version = "unstable-hydrasdr";
  src = fetchFromGitHub {
    owner = "hydrasdr";
    repo = "SDRPlusPlus";
    rev = "master";
    hash = "sha256-TD39CFO2kEZGcbu/cyGT3WVb4TbvKbj1HNon6vu+UNA=";
  };
  # The fork adds a HydraSDR source module needing libhydrasdr. On Darwin,
  # nixpkgs' rtaudio (pulled in by the audio source/sink modules) advertises
  # `Requires: jack` in its pkg-config file but does not propagate JACK there,
  # so the configure step fails resolving `jack`. Provide it explicitly; on
  # Linux it already comes in transitively.
  buildInputs = (old.buildInputs or [ ]) ++ [ libhydrasdr ]
    ++ lib.optionals stdenv.hostPlatform.isDarwin [ libjack2 ];
  # nixpkgs sdrpp's postPatch uses --replace-fail against the upstream version
  # string, which the fork source does not contain. Redo it fork-tolerant:
  # guard each file and use --replace-quiet so a missing pattern is not fatal.
  postPatch = ''
    if [ -f decoder_modules/m17_decoder/src/m17dsp.h ]; then
      substituteInPlace decoder_modules/m17_decoder/src/m17dsp.h \
        --replace-quiet "codec2.h" "codec2/codec2.h"
    fi
    if [ -f core/src/version.h ]; then
      substituteInPlace core/src/version.h \
        --replace-quiet "1.3.0" "unstable-hydrasdr"
    fi
  '';
  # SDR++ builds its plugins as the platform's native shared-library type, so
  # the sanity check must look for .dylib on Darwin, not the Linux .so.
  doInstallCheck = true;
  installCheckPhase =
    let ext = stdenv.hostPlatform.extensions.sharedLibrary; in ''
      runHook preInstallCheck
      test -e "$out/lib/sdrpp/plugins/hydrasdr_source${ext}"
      test -e "$out/lib/sdrpp/plugins/soapy_source${ext}"
      runHook postInstallCheck
    '';
  meta = (old.meta or { }) // {
    description = "SDR++ (HydraSDR fork): cross-platform SDR receiver";
    homepage = "https://github.com/hydrasdr/SDRPlusPlus";
  };
})
