# Universal Radio Hacker, PentHertz "urh-ng" fork.
#
# The Docker image installs a prebuilt .deb, but URH is a normal Python/Cython
# application (that is how nixpkgs builds `urh`), so we compile the fork from
# source by overriding the nixpkgs derivation's source. No .deb needed.
{ lib, stdenv, fetchFromGitHub, urh, python3Packages
, libhydrasdr, signalhound-sdk, harogic-htra-sdk }:

let
  # Extra device backends the PentHertz fork adds. HydraSDR is cross-platform;
  # SignalHound (x86_64-linux only) and Harogic (Linux only) are proprietary
  # SDKs restricted to specific platforms. Include each one only where it
  # actually builds: wiring them in unconditionally makes urh-ng itself
  # impossible to evaluate on macOS and aarch64-linux, which silently drops
  # URH from the SDR environments there (resolvePkg treats a throwing drvPath
  # as "package absent").
  backends = builtins.filter (p: lib.meta.availableOn stdenv.hostPlatform p)
    [ libhydrasdr harogic-htra-sdk signalhound-sdk ];
in
urh.overrideAttrs (old: {
  pname = "urh-ng";
  version = "unstable-penthertz";
  src = fetchFromGitHub {
    owner = "PentHertz";
    repo = "urh-ng";
    rev = "master";
    hash = "sha256-2CLg4Tn8l0VQH+gfEFrftb43g6zf/lxOpGTUniciY7c=";
  };
  # The fork's metadata requires PyQt6; make sure it is present so the Python
  # runtime-deps check passes and the app finds its Qt bindings.
  propagatedBuildInputs = (old.propagatedBuildInputs or [ ]) ++ [ python3Packages.pyqt6 ];

  # HydraSDR + Harogic are Cython extensions compiled when their headers/libs
  # are present; SignalHound is loaded at runtime via ctypes. Provide whichever
  # of them build on this platform so URH stops reporting them as missing
  # drivers, without dropping URH itself where they do not.
  buildInputs = (old.buildInputs or [ ]) ++ backends;

  # The runtime-loaded (ctypes) SignalHound/Harogic libs must be findable at the
  # OS dynamic-loader path, which differs by platform (DYLD_ on Darwin). Only
  # emitted when a backend is actually present for this host.
  makeWrapperArgs = (old.makeWrapperArgs or [ ])
    ++ lib.optionals (backends != [ ]) [
      "--prefix"
      (if stdenv.hostPlatform.isDarwin then "DYLD_LIBRARY_PATH" else "LD_LIBRARY_PATH")
      ":"
      (lib.makeLibraryPath backends)
    ];
  meta = (old.meta or { }) // {
    description = "Universal Radio Hacker (PentHertz urh-ng fork), built from source";
    homepage = "https://github.com/PentHertz/urh-ng";
  };
})
