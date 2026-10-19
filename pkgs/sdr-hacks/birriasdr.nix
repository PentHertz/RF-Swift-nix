# BirriaSDR (luigifcruz): drives a MediaTek MT7921AU/MT7961 USB Wi-Fi dongle
# as a 40 MSps I/Q receiver from user space over libusb (libbirriasdr,
# birria_rx, birriasdr.pc). The NDS32 RAM program it loads is prebuilt in
# src/chips/mt7921_image.h, so no firmware toolchain is involved. Matches
# RF-Swift-images' birriasdr_sdrhacks_install (sdr_hacks), udev rule included;
# the host must not bind mt7921u to the dongle (blacklist it, then replug).
{ lib, stdenv, fetchFromGitHub, cmake, pkg-config, libusb1 }:

stdenv.mkDerivation {
  pname = "birriasdr";
  version = "0.1.0-unstable-2026-10-18";

  src = fetchFromGitHub {
    owner = "luigifcruz";
    repo = "BirriaSDR";
    rev = "2e018553939dd6f18a11724fd07ef0fb42ea6279";
    hash = "sha256-sGdAbHj6bAq88QgUXF/47Pr4MfWFedTWSHhYk8eexcs=";
  };

  # Upstream builds with -Werror against the compilers it was tested with;
  # a newer GCC's new warnings must not fail the build (the images retry
  # without it for the same reason).
  postPatch = ''
    substituteInPlace CMakeLists.txt --replace-fail " -Werror)" ")"
  '';

  nativeBuildInputs = [ cmake pkg-config ];
  buildInputs = [ libusb1 ];

  cmakeFlags = [ "-DCMAKE_C_STANDARD=17" ];

  # Offline unit tests (tuning maths, filter set-up, a recorded RF trace).
  doCheck = true;

  postInstall = lib.optionalString stdenv.hostPlatform.isLinux ''
    install -Dm644 /dev/stdin $out/lib/udev/rules.d/99-birriasdr.rules <<'EOF'
    # BirriaSDR: COMFAST MT7961 dongle and the generic MediaTek MT7961 ID.
    # The host must not bind mt7921u to it (blacklist mt7921u, then replug).
    SUBSYSTEM=="usb", ATTRS{idVendor}=="3574", ATTRS{idProduct}=="6211", MODE="0666", TAG+="uaccess"
    SUBSYSTEM=="usb", ATTRS{idVendor}=="0e8d", ATTRS{idProduct}=="7961", MODE="0666", TAG+="uaccess"
    EOF
  '';

  meta = {
    description = "MediaTek MT7921AU/MT7961 USB Wi-Fi dongle as a 40 MSps I/Q receiver";
    homepage = "https://github.com/luigifcruz/BirriaSDR";
    license = lib.licenses.mit;
    platforms = lib.platforms.linux ++ lib.platforms.darwin;
    mainProgram = "birria_rx";
  };
}
