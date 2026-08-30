# SDR++ (SDRPlusPlus), HydraSDR fork. Overrides the nixpkgs sdrpp source so we
# reuse its full set of source/sink build flags and dependencies.
{ lib, stdenv, fetchFromGitHub, sdrpp, libhydrasdr, libjack2 }:

# Enable the SDR source modules nixpkgs leaves off. These are *function
# arguments* of the nixpkgs sdrpp derivation (they select both cmake flags and
# buildInputs), so they must be flipped with `.override` before `.overrideAttrs`
# swaps in the fork source — an overrideAttrs alone cannot reach them, which is
# why bladeRF/PlutoSDR/USRP were silently absent from the built plugins:
#   * bladerf_source defaulted to Linux-only upstream; libbladeRF builds on
#     macOS too, so enable it everywhere.
#   * usrp_source defaults off on every platform; uhd builds on all of ours.
#   * plutosdr_source stays Linux-only: nixpkgs' libad9361 is broken on
#     aarch64-darwin (it ships a pkg-config file pointing at empty include/lib
#     dirs — no ad9361.h, no dylib) and the fork's Darwin CMake branch hardcodes
#     /Library/Frameworks/iio.framework, which Nix does not provide. On Linux it
#     resolves libiio+libad9361 via pkg-config and builds fine.
# Left off deliberately: sdrplay (proprietary API), perseus (libperseus-sdr not
# in nixpkgs), and the fork-only fobossdr/rfnm (libfobos/librfnm not packaged).
(sdrpp.override {
  bladerf_source = true;
  usrp_source = true;
  plutosdr_source = stdenv.hostPlatform.isLinux;
}).overrideAttrs (old: {
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
      # Guard the modules we explicitly enabled above so a regression that drops
      # them (e.g. a lost .override) fails the build instead of shipping quietly.
      test -e "$out/lib/sdrpp/plugins/bladerf_source${ext}"
      test -e "$out/lib/sdrpp/plugins/usrp_source${ext}"
      ${lib.optionalString stdenv.hostPlatform.isLinux ''
        test -e "$out/lib/sdrpp/plugins/plutosdr_source${ext}"
      ''}
      runHook postInstallCheck
    '';
  meta = (old.meta or { }) // {
    description = "SDR++ (HydraSDR fork): cross-platform SDR receiver";
    homepage = "https://github.com/hydrasdr/SDRPlusPlus";
  };
})
