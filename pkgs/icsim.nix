# ICSim (zombieCraig/ICSim): instrument-cluster simulator on a SocketCAN bus,
# with a gamepad/keyboard "controls" window that injects the CAN frames.
# Matches RF-Swift-images' icsim_soft_install (`make`, wrappers `icsim`,
# `icsim-controls`, `icsim-setup-vcan`).
#
# The image cd's into the checkout because both programs load their artwork from
# DATA_DIR ("./data/"); here DATA_DIR is compiled in as $out/share/icsim/data/,
# so the binaries run from anywhere. The repo commits a prebuilt x86_64 lib.o
# (from can-utils); we rebuild it from lib.c so other arches link.
{ lib, stdenv, fetchFromGitHub, pkg-config, makeWrapper, SDL2, SDL2_image
, can-utils, iproute2, kmod }:

stdenv.mkDerivation {
  pname = "icsim";
  version = "unstable-2025-09-18";

  src = fetchFromGitHub {
    owner = "zombieCraig";
    repo = "ICSim";
    rev = "2b3333ef866987d8adc9c15ff15b9b9189edf85b";
    hash = "sha256-yMkOG5q60xhvmszVV8aSEeZ5pNXqJ2yD0ige7EbhH/8=";
  };

  nativeBuildInputs = [ pkg-config makeWrapper ];
  buildInputs = [ SDL2 SDL2_image ];

  postPatch = ''
    substituteInPlace icsim.c controls.c \
      --replace-fail '#define DATA_DIR "./data/"' "#define DATA_DIR \"$out/share/icsim/data/\""
    # setup_vcan.sh hardcodes sudo; only use it when not already root.
    substituteInPlace setup_vcan.sh --replace-fail 'sudo ' '$SUDO '
    { printf '%s\n' '#!/usr/bin/env bash' 'SUDO=; [ "$EUID" -eq 0 ] || SUDO=sudo'
      cat setup_vcan.sh; } > setup_vcan.sh.new
    mv setup_vcan.sh.new setup_vcan.sh
  '';

  buildPhase = ''
    runHook preBuild
    rm -f lib.o
    $CC -O2 -c lib.c -o lib.o
    make CC="$CC" \
      CFLAGS="-O2 -Wall $(pkg-config --cflags sdl2 SDL2_image)" \
      LDFLAGS="$(pkg-config --libs sdl2 SDL2_image)"
    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall
    install -Dm755 icsim $out/bin/icsim
    # controls exec()s canplayer (can-utils) for the background CAN traffic.
    install -Dm755 controls $out/libexec/icsim/controls
    makeWrapper $out/libexec/icsim/controls $out/bin/icsim-controls \
      --prefix PATH : ${lib.makeBinPath [ can-utils ]}
    install -Dm644 -t $out/share/icsim/data data/*.png data/sample-can.log
    install -Dm755 setup_vcan.sh $out/libexec/icsim/setup_vcan.sh
    patchShebangs $out/libexec/icsim/setup_vcan.sh
    # Suffix, so a host modprobe/ip (matching the running kernel) wins.
    makeWrapper $out/libexec/icsim/setup_vcan.sh $out/bin/icsim-setup-vcan \
      --suffix PATH : ${lib.makeBinPath [ iproute2 kmod ]}
    runHook postInstall
  '';

  meta = {
    description = "Instrument Cluster Simulator for SocketCAN (virtual CAN bus training target)";
    homepage = "https://github.com/zombieCraig/ICSim";
    license = lib.licenses.gpl3Only;
    platforms = lib.platforms.linux;
    mainProgram = "icsim";
  };
}
