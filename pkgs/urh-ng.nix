# Universal Radio Hacker, PentHertz "urh-ng" fork.
#
# The Docker image installs a prebuilt .deb, but URH is a normal Python/Cython
# application (that is how nixpkgs builds `urh`), so we compile the fork from
# source by overriding the nixpkgs derivation's source. No .deb needed.
{ lib, fetchFromGitHub, urh, python3Packages
, libhydrasdr, signalhound-sdk, harogic-htra-sdk }:

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

  # Extra device backends the PentHertz fork adds: HydraSDR + Harogic are Cython
  # extensions compiled when their headers/libs are present; SignalHound is
  # loaded at runtime via ctypes. Provide all three so URH stops reporting them
  # as missing drivers.
  buildInputs = (old.buildInputs or [ ]) ++ [ libhydrasdr harogic-htra-sdk signalhound-sdk ];

  # The runtime-loaded (ctypes) SignalHound/Harogic libs must be findable.
  makeWrapperArgs = (old.makeWrapperArgs or [ ]) ++ [
    "--prefix"
    "LD_LIBRARY_PATH"
    ":"
    (lib.makeLibraryPath [ signalhound-sdk harogic-htra-sdk libhydrasdr ])
  ];
  meta = (old.meta or { }) // {
    description = "Universal Radio Hacker (PentHertz urh-ng fork), built from source";
    homepage = "https://github.com/PentHertz/urh-ng";
  };
})
