# SDR++ (SDRPlusPlus), HydraSDR fork. Overrides the nixpkgs sdrpp source so we
# reuse its full set of source/sink build flags and dependencies, then adds the
# device sources RF Swift's images ship on top: HydraSDR, RFNM, Harogic,
# SignalHound BB60 and Deepace KC908, each only on the architectures its
# library exists for (see `available` below).
{ lib, stdenv, fetchFromGitHub, sdrpp, libhydrasdr, libjack2
, soapysdr-with-plugins
, signalhound-sdk ? null, harogic-htra-sdk ? null, kc908-sdk ? null }:

let
  inherit (stdenv.hostPlatform) isLinux isDarwin;
  ext = stdenv.hostPlatform.extensions.sharedLibrary;

  # A vendor library counts only where nixpkgs' platform metadata says it
  # builds: harogic-htra-sdk on x86_64/aarch64 Linux, signalhound-sdk also on
  # aarch64 macOS, kc908-sdk (FTDI D3XX from the PentHertz mirror) on x86_64
  # Linux only. Elsewhere the matching module is simply left out.
  available = p: p != null && lib.meta.availableOn stdenv.hostPlatform p;
  withHarogic = available harogic-htra-sdk;
  withSignalHound = available signalhound-sdk;
  withKcsdr = available kc908-sdk;
  # The fork's rfnm_source is written against a librfnm snapshot older than
  # any released API (`librfnm::find`, `rx_stream(format, int*)`): neither the
  # current librfnm (rfnm::device) nor the last pre-refactor revision matches
  # it. RFNM devices reach SDR++ through the Soapy source instead (SoapyRFNM
  # is in RF Swift's plugin set), so the native module stays off.
  withRfnm = false;

  # PentHertz's SDR++ fork carries the SignalHound BB source module (the one
  # RF Swift's images download prebuilt); the HydraSDR fork does not, so the
  # module directory is grafted into the tree and built from source here,
  # against this very SDR++ core rather than a binary made for another one.
  penthertzSrc = fetchFromGitHub {
    owner = "PentHertz";
    repo = "SDRPlusPlus";
    rev = "c7cfe8827dcd7ec35fb0783ab3deb819cc87e0a6";
    hash = "sha256-GeQ+q/x3CH4mSB1kAD4cXqnY0FsWin5K+F+ktYT9h80=";
  };
in

# Enable the SDR source modules nixpkgs leaves off. These are *function
# arguments* of the nixpkgs sdrpp derivation (they select both cmake flags and
# buildInputs), so they must be flipped with `.override` before `.overrideAttrs`
# swaps in the fork source - an overrideAttrs alone cannot reach them, which is
# why bladeRF/PlutoSDR/USRP were silently absent from the built plugins:
#   * bladerf_source defaulted to Linux-only upstream; libbladeRF builds on
#     macOS too, so enable it everywhere.
#   * usrp_source defaults off on every platform; uhd builds on all of ours.
#   * plutosdr_source stays Linux-only: nixpkgs' libad9361 is broken on
#     aarch64-darwin (it ships a pkg-config file pointing at empty include/lib
#     dirs - no ad9361.h, no dylib) and the fork's Darwin CMake branch hardcodes
#     /Library/Frameworks/iio.framework, which Nix does not provide. On Linux it
#     resolves libiio+libad9361 via pkg-config and builds fine.
#   * soapysdr-with-plugins is RF Swift's own plugin set (pkgs/default.nix), so
#     the Soapy source also sees HydraSDR, RFNM, XTRX, LiteX M2SDR and uSDR.
# Left off deliberately: sdrplay (proprietary API whose nixpkgs source is
# currently unavailable), perseus (libperseus-sdr not in nixpkgs) and the
# fork-only fobossdr (libfobos not packaged).
(sdrpp.override {
  bladerf_source = true;
  usrp_source = true;
  plutosdr_source = isLinux;
  inherit soapysdr-with-plugins;
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
    ++ lib.optionals isDarwin [ libjack2 ]
    ++ lib.optional withHarogic harogic-htra-sdk
    ++ lib.optional withSignalHound signalhound-sdk
    ++ lib.optional withKcsdr kc908-sdk;

  cmakeFlags = (old.cmakeFlags or [ ]) ++ [
    (lib.cmakeBool "OPT_BUILD_HAROGIC_SOURCE" withHarogic)
    (lib.cmakeBool "OPT_BUILD_KCSDR_SOURCE" withKcsdr)
    (lib.cmakeBool "OPT_BUILD_RFNM_SOURCE" withRfnm)
    (lib.cmakeBool "OPT_BUILD_SIGNALHOUNDBB_SOURCE" withSignalHound)
  ] ++ lib.optionals withSignalHound [
    # The module's CMake searches /usr for the Signal Hound API; hand it the
    # Nix SDK instead (a pre-set cache entry short-circuits find_path/find_library).
    "-DBBAPI_INCLUDE_DIR=${signalhound-sdk}/include"
    "-DBBAPI_LIBRARY=${signalhound-sdk}/lib/libbb_api${ext}"
  ];

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
  '' + lib.optionalString withHarogic ''
    # harogic_source expects the SDK at /opt/htraapi (the vendor installer's
    # layout); point it at the Nix package.
    substituteInPlace source_modules/harogic_source/CMakeLists.txt \
      --replace-fail '/opt/htraapi/lib/''${CMAKE_SYSTEM_PROCESSOR}/' '${harogic-htra-sdk}/lib/' \
      --replace-fail '/opt/htraapi/inc/' '${harogic-htra-sdk}/include/'
  '' + lib.optionalString withKcsdr ''
    # kcsdr_source expects FTDI's Windows-style D3XX bundle checked in under
    # vendor/. Use the Linux library from kc908-sdk. The Linux D3XX API takes
    # a timeout (DWORD) where the Windows one takes an OVERLAPPED pointer, so
    # the NULL the source passes there is an int-conversion error with gcc 14+.
    substituteInPlace source_modules/kcsdr_source/CMakeLists.txt \
      --replace-fail '"vendor/FTD3XXLibrary_1.3.0.10/x64/DLL"' '"${kc908-sdk}/lib"' \
      --replace-fail '"vendor/FTD3XXLibrary_1.3.0.10"' '"${kc908-sdk}/include"' \
      --replace-fail 'PRIVATE FTD3XX)' 'PRIVATE ftd3xx)'
    substituteInPlace source_modules/kcsdr_source/src/kcsdr.c \
      --replace-fail '"../vendor/FTD3XXLibrary_1.3.0.10/FTD3XX.h"' '<ftd3xx.h>' \
      --replace-fail '&sent, NULL)' '&sent, 0)' \
      --replace-fail '&received, NULL)' '&received, 0)' \
      --replace-fail 'Sleep(50);' 'usleep(50000);'
    # The driver was written on Windows: Sleep() and implicit malloc/free.
    # An undefined Sleep would make dlopen() of the plugin fail at run time.
    sed -i 's|#include <stddef.h>|#include <stddef.h>\n#include <stdlib.h>\n#include <unistd.h>|' \
      source_modules/kcsdr_source/src/kcsdr.c
  '' + lib.optionalString withSignalHound ''
    # Graft the SignalHound BB60 source module from the PentHertz fork.
    cp -r ${penthertzSrc}/source_modules/signalhound_bb_source source_modules/
    chmod -R u+w source_modules/signalhound_bb_source
    cat >> CMakeLists.txt <<'CMAKE'

# RF Swift: SignalHound BB60 source (from the PentHertz fork).
option(OPT_BUILD_SIGNALHOUNDBB_SOURCE "Build SignalHound BB Source Module (Dependencies: libbb_api)" OFF)
if (OPT_BUILD_SIGNALHOUNDBB_SOURCE)
add_subdirectory("source_modules/signalhound_bb_source")
endif (OPT_BUILD_SIGNALHOUNDBB_SOURCE)
CMAKE
  '';

  # SDR++ builds its plugins as the platform's native shared-library type, so
  # the sanity check must look for .dylib on Darwin, not the Linux .so.
  doInstallCheck = true;
  installCheckPhase = ''
    runHook preInstallCheck
    test -e "$out/lib/sdrpp/plugins/hydrasdr_source${ext}"
    test -e "$out/lib/sdrpp/plugins/soapy_source${ext}"
    # Guard the modules we explicitly enabled above so a regression that drops
    # them (e.g. a lost .override) fails the build instead of shipping quietly.
    test -e "$out/lib/sdrpp/plugins/bladerf_source${ext}"
    test -e "$out/lib/sdrpp/plugins/usrp_source${ext}"
    ${lib.optionalString isLinux ''
      test -e "$out/lib/sdrpp/plugins/plutosdr_source${ext}"
    ''}
    ${lib.optionalString withHarogic ''test -e "$out/lib/sdrpp/plugins/harogic_source${ext}"''}
    ${lib.optionalString withSignalHound ''test -e "$out/lib/sdrpp/plugins/signalhound_bb_source${ext}"''}
    ${lib.optionalString withKcsdr ''test -e "$out/lib/sdrpp/plugins/kcsdr_source${ext}"''}
    ${lib.optionalString withRfnm ''test -e "$out/lib/sdrpp/plugins/rfnm_source${ext}"''}
    runHook postInstallCheck
  '';

  passthru = (old.passthru or { }) // {
    # Which vendor sources this build carries, for tooling and tests.
    vendorSources = lib.optional withHarogic "harogic"
      ++ lib.optional withSignalHound "signalhound_bb"
      ++ lib.optional withKcsdr "kcsdr"
      ++ lib.optional withRfnm "rfnm";
  };

  meta = (old.meta or { }) // {
    description = "SDR++ (HydraSDR fork): cross-platform SDR receiver, with the HydraSDR, RFNM, Harogic, SignalHound and KC908 sources";
    homepage = "https://github.com/hydrasdr/SDRPlusPlus";
  };
})
