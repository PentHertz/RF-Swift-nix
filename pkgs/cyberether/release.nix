# CyberEther from upstream's prebuilt release binaries (the luigifcruz/CyberEther
# GitHub release tarballs), next to the source build in ./default.nix. Nothing
# is compiled, so it installs in seconds instead of a long, memory-hungry
# serial build, and it covers aarch64 Linux and macOS, which the source build
# does not. Each tarball holds the `cyberether` launcher and libjetstream, with
# every SDR driver (RTL-SDR, Airspy/HF+, HackRF, LimeSDR, bladeRF, PlutoSDR)
# linked in statically.
#
#   * Linux: autoPatchelf points the binaries at nixpkgs' glibc, libgudev,
#     udev and Vulkan loader. What libjetstream dlopens at runtime (GLFW's
#     X11/Wayland backends, miniaudio's ALSA/PulseAudio/JACK, libsecret for the
#     assistant's keys) goes on its RUNPATH too.
#   * macOS: the dylib links system frameworks only (Metal, AudioToolbox, ...)
#     and finds itself through @loader_path, so it is installed as is; no strip,
#     which would invalidate the linker's ad-hoc signature.
#
# Its SoapySDR block (the fallback for radios the built-in drivers do not cover,
# e.g. USRP) dlopens libSoapySDR and accepts only ABI "0.8", the 0.8.1 release.
# nixpkgs ships a later snapshot (ABI "0.8-3") whose device modules would not
# load into a 0.8.1 library either, so that block reports SoapySDR as missing
# here; the source build (pkg-cyberether) patches the check and uses RF Swift's
# SoapySDR. CYBERETHER_SOAPYSDR_LIBRARY points it at a 0.8.1 library of your own.
#
# The CUDA builds upstream also publishes are left out: they bundle the CUDA 12
# runtime and still need a matching host NVIDIA driver.
{ lib
, stdenv
, fetchurl
, autoPatchelfHook
, makeWrapper
, libgudev
, udev
, vulkan-loader
, libx11
, libxcursor
, libxext
, libxi
, libxinerama
, libxrandr
, libxrender
, libxxf86vm
, wayland
, libxkbcommon
, libdecor
, alsa-lib
, libpulseaudio
, libjack2
, libsecret
}:

let
  version = "1.15.0";
  assets = {
    x86_64-linux = {
      name = "cyberether-linux-x86_64.tar.gz";
      hash = "sha256-KWYMbhvPwPrAVAUm8P6gjRqeZ+YTMbdD3L1pT9Bdn9I=";
    };
    aarch64-linux = {
      name = "cyberether-linux-aarch64.tar.gz";
      hash = "sha256-oIDDeyhEvJrZmrFvQ5CUyVRPnPg7vxq0rZmWSBG2Y5M=";
    };
    aarch64-darwin = {
      name = "cyberether-macos-arm64.tar.gz";
      hash = "sha256-7Yt4+sKMFj8UG2lRd+w4HUP2m1xgIPGb+XAMPAy4IvM=";
    };
  };
  asset = assets.${stdenv.hostPlatform.system}
    or (throw "cyberether-release: no upstream binary for ${stdenv.hostPlatform.system}");
  inherit (stdenv.hostPlatform) isLinux;
  libjetstream = "libjetstream${stdenv.hostPlatform.extensions.sharedLibrary}";
in
stdenv.mkDerivation {
  pname = "cyberether-release";
  inherit version;

  src = fetchurl {
    url = "https://github.com/luigifcruz/CyberEther/releases/download/v${version}/${asset.name}";
    inherit (asset) hash;
  };
  # The tarball has no top-level directory.
  sourceRoot = ".";

  nativeBuildInputs = [ makeWrapper ] ++ lib.optionals isLinux [ autoPatchelfHook ];
  buildInputs = lib.optionals isLinux [ stdenv.cc.cc.lib libgudev udev vulkan-loader ];
  # dlopen()ed by libjetstream itself (GLFW and miniaudio are linked into it),
  # so they go on every RUNPATH: runtimeDependencies would reach only the
  # launcher's, which a library's dlopen does not search.
  appendRunpaths = map (p: "${lib.getLib p}/lib") (lib.optionals isLinux [
    libx11 libxcursor libxext libxi libxinerama libxrandr libxrender libxxf86vm
    wayland libxkbcommon libdecor
    alsa-lib libpulseaudio libjack2
    libsecret
  ]);

  dontConfigure = true;
  dontBuild = true;
  dontStrip = true;

  # The macOS launcher finds libjetstream only next to itself (@loader_path,
  # @executable_path), and rewriting its rpath would void the signature, so
  # both stay together under libexec and bin/ gets a wrapper (on Linux too, for
  # one layout).
  installPhase = ''
    runHook preInstall
    install -Dm755 cyberether $out/libexec/cyberether/cyberether
    install -Dm755 ${libjetstream} $out/libexec/cyberether/${libjetstream}
    makeWrapper $out/libexec/cyberether/cyberether $out/bin/cyberether
    runHook postInstall
  '';

  meta = {
    description = "CyberEther: heterogeneous SDR signal visualisation (upstream release binaries)";
    homepage = "https://github.com/luigifcruz/CyberEther";
    changelog = "https://github.com/luigifcruz/CyberEther/releases/tag/v${version}";
    license = lib.licenses.mit;
    sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
    platforms = builtins.attrNames assets;
    mainProgram = "cyberether";
  };
}
