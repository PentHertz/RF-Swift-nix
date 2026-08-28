{ lib, stdenv, fetchFromGitHub, meson, ninja, pkg-config, libconfig }:
stdenv.mkDerivation {
  pname = "socketcand"; version = "unstable";
  src = fetchFromGitHub { owner = "linux-can"; repo = "socketcand"; rev = "master"; hash = "sha256-Pvh0lowK3mQLRu+TotjZS75bwztNvbY7rC3gZUSdjVA="; };
  nativeBuildInputs = [ meson ninja pkg-config ];
  buildInputs = [ libconfig ];
  # SocketCAN is a Linux kernel subsystem; socketcand builds only on Linux. Declaring
  # this lets resolvePkg drop it cleanly on macOS instead of hard-failing the
  # automotive environment build there.
  meta = { description = "Daemon that provides access to CAN interfaces over TCP"; homepage = "https://github.com/linux-can/socketcand"; license = lib.licenses.bsd3; platforms = lib.platforms.linux; mainProgram = "socketcand"; };
}
