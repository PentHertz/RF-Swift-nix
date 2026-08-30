# litex-m2sdr: host software for the LiteX M2SDR (FlUxIuS fork of enjoy-digital's
# litex_m2sdr): the userspace tools (m2sdr_util, m2sdr_rf, m2sdr_play/record,
# ...) from software/user and the SoapySDR module from software/soapysdr —
# what the sdrsa_devices image's litexm2sdr_devices_install builds with
# build.py, minus the LitePCIe kernel module (a host-side driver, not a Nix
# concern; the tools and module compile against its header only). Linux-only:
# the LitePCIe interface is a Linux character device.
{ lib, stdenv, fetchFromGitHub, cmake, pkg-config, soapysdr }:

stdenv.mkDerivation (finalAttrs: {
  pname = "litex-m2sdr";
  version = "unstable-2025";

  src = fetchFromGitHub {
    owner = "FlUxIuS";
    repo = "litex_m2sdr";
    rev = "97a2cc7f19ec40914fe604e688cb96a2f157618d";
    hash = "sha256-jVNuKKicfjd6kgXakucQ9fxRSIzSu7rJRNnTz5yNmTc=";
  };
  sourceRoot = "${finalAttrs.src.name}/litex_m2sdr/software";

  nativeBuildInputs = [ cmake pkg-config ];
  buildInputs = [ soapysdr ];

  # Two build systems side by side (Makefile tools, CMake Soapy module); drive
  # them by hand rather than through the cmake hook.
  dontUseCmakeConfigure = true;
  buildPhase = ''
    runHook preBuild
    make -C user CC=$CC
    cmake -S soapysdr -B soapysdr/build \
      -DCMAKE_INSTALL_PREFIX=$out \
      -DSoapySDR_DIR=${soapysdr}/share/cmake/SoapySDR/ \
      -DUSE_LITEETH=OFF -DCMAKE_BUILD_TYPE=Release \
      -DCMAKE_POLICY_VERSION_MINIMUM=3.5
    make -C soapysdr/build
    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall
    make -C soapysdr/build install
    mkdir -p $out/bin
    for f in user/m2sdr_*; do
      [ -f "$f" ] && [ -x "$f" ] && install -Dm755 "$f" "$out/bin/$(basename "$f")"
    done
    runHook postInstall
  '';

  meta = {
    description = "LiteX M2SDR host tools and SoapySDR module";
    homepage = "https://github.com/FlUxIuS/litex_m2sdr";
    license = lib.licenses.bsd2;
    platforms = lib.platforms.linux;
  };
})
