# Little Snitch for Linux (obdev.at): a per-application network monitor and
# firewall. RF Swift's images install it in the core build
# (corebuild.sh: littlesnitch_soft_install) from the vendor .deb; here we use the
# self-contained musl tarball obdev also publishes, whose `littlesnitch` binary
# is a statically linked ELF - so it needs no autoPatchelf and runs as-is.
#
# Proprietary (unfree). The daemon needs CAP_BPF, CAP_SYS_ADMIN,
# CAP_DAC_READ_SEARCH and CAP_PERFMON at runtime (run the container/host with
# those), and mounting tracefs plus running the daemon require root - the
# wrapper mirrors the image's tracefs setup best-effort.
{ lib, stdenv, fetchurl, makeWrapper, util-linux }:

let
  version = "1.1.0";
  arch = {
    "x86_64-linux" = "amd64";
    "aarch64-linux" = "arm64";
    "riscv64-linux" = "riscv64";
  }.${stdenv.hostPlatform.system}
    or (throw "littlesnitch: unsupported platform ${stdenv.hostPlatform.system}");
  hash = {
    amd64 = "sha256-8dRDNf3qer0/C9QYGXuIpl2QJKsJlYDnF5lRFIvQfOE=";
    arm64 = "sha256-n6OH3jrU1VEGZblK4xVvMIKUxnP2sWkpB6xutilK7qM=";
    riscv64 = "sha256-Ru1Lbo/Cj1EzSPKwS/1EYcdigw7N354QPpL8k5iEm4Y=";
  }.${arch};
in
stdenv.mkDerivation {
  pname = "littlesnitch";
  inherit version;

  src = fetchurl {
    url = "https://obdev.at/downloads/littlesnitch-linux/littlesnitch-${version}-${arch}-linux-musl.tar.gz";
    inherit hash;
  };

  nativeBuildInputs = [ makeWrapper ];
  dontConfigure = true;
  dontBuild = true;

  installPhase = ''
    runHook preInstall
    install -Dm755 usr/bin/littlesnitch $out/libexec/littlesnitch
    install -Dm644 usr/lib/systemd/system/littlesnitch.service \
      $out/lib/systemd/system/littlesnitch.service
    if [ -f usr/share/doc/littlesnitch/copyright ]; then
      install -Dm644 usr/share/doc/littlesnitch/copyright \
        $out/share/doc/littlesnitch/copyright
    fi

    # Mirror RF Swift's image wrapper: make sure the tracefs mount Little Snitch
    # expects is present (best-effort; needs root), then exec the tool.
    makeWrapper $out/libexec/littlesnitch $out/bin/littlesnitch \
      --prefix PATH : ${lib.makeBinPath [ util-linux ]} \
      --run 'if ! mountpoint -q /sys/kernel/tracing 2>/dev/null; then mkdir -p /sys/kernel/tracing 2>/dev/null && mount -t tracefs tracefs /sys/kernel/tracing 2>/dev/null || true; fi'
    runHook postInstall
  '';

  meta = {
    description = "Little Snitch for Linux: per-application network monitor and firewall (obdev, proprietary)";
    homepage = "https://obdev.at/products/littlesnitch-linux/";
    license = lib.licenses.unfree;
    sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
    platforms = [ "x86_64-linux" "aarch64-linux" "riscv64-linux" ];
    mainProgram = "littlesnitch";
  };
}
