# DecSAT (CasualArclamp, ex-DecDVB): Rust satellite receiver - DVB-S2/S2X with
# ACM (GSE -> IP PCAP, MPEG-TS), DVB-S, SCPC modems and DVB-CID, with an
# SDR++-style egui GUI (`decsat-gui`) and a CLI (`decsat`). Live input is a
# HackRF One through a pure-Rust USB driver; other SDRs through I/Q captures
# (`decsat test-signals DIR` generates some). Matches RF-Swift-images'
# decsat_soft_install (sdr_full): upstream ships Windows builds only, so both
# apps are built from the tagged source, whose libopus and libxaac submodules
# the -sys crates compile (libopus with CMake).
#
# The GUI dlopens its window system and GL (winit: X11/Wayland/xkbcommon,
# glutin: EGL/GL), so those go on its RUNPATH; the TV player runs ffmpeg and
# the radar map curl, both put on the wrappers' PATH.
{ lib, stdenv, rustPlatform, fetchFromGitHub, cmake, pkg-config, makeWrapper
, alsa-lib, libx11, libxcursor, libxi, libxrandr, libxkbcommon, wayland, libGL
, ffmpeg, curl }:

rustPlatform.buildRustPackage (finalAttrs: {
  pname = "decsat";
  version = "0.10.17";

  src = fetchFromGitHub {
    owner = "CasualArclamp";
    repo = "DecSAT";
    rev = "v${finalAttrs.version}";
    fetchSubmodules = true;
    hash = "sha256-C56anz2jnLIVuM46XRjOUhl10KVILSu0AQjNSdFbDcg=";
  };

  cargoHash = "sha256-0s+frrjAWwEawBgxTw9nAwE4/RlEbtxEg6orTTCAcJw=";

  cargoBuildFlags = [ "-p" "decsat-cli" "-p" "decsat-gui" ];

  nativeBuildInputs = [ cmake pkg-config makeWrapper ];
  buildInputs = lib.optionals stdenv.hostPlatform.isLinux [ alsa-lib ];

  # cmake is for the opus-sys build script, not the top-level build.
  dontUseCmakeConfigure = true;

  # The workspace tests decode multi-second synthetic captures and rebuild the
  # whole tree in test mode; the CLI is exercised in installCheckPhase instead.
  doCheck = false;
  doInstallCheck = true;
  installCheckPhase = ''
    runHook preInstallCheck
    $out/bin/decsat --help > /dev/null
    runHook postInstallCheck
  '';

  postFixup = lib.optionalString stdenv.hostPlatform.isLinux ''
    patchelf --add-rpath ${lib.makeLibraryPath [
      libx11 libxcursor libxi libxrandr libxkbcommon wayland libGL
    ]} $out/bin/decsat-gui
  '' + ''
    for b in decsat decsat-gui; do
      wrapProgram $out/bin/$b --prefix PATH : ${lib.makeBinPath [ ffmpeg curl ]}
    done
  '';

  meta = {
    description = "DVB-S2/S2X, DVB-S and SCPC satellite receiver with GUI and CLI";
    homepage = "https://github.com/CasualArclamp/DecSAT";
    license = lib.licenses.gpl3Plus;
    # Linux, as upstream and the images build it. On macOS libxaac's generic
    # QMF kernels are compiled out (#if !__ARM_NEON__, which Apple clang
    # defines on arm64) while the -sys crate does not build the ARM assembly.
    platforms = lib.platforms.linux;
    mainProgram = "decsat-gui";
  };
})
