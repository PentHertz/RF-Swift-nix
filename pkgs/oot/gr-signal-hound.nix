# gr-signal-hound: dedicated GNU Radio OOT source block for Signal Hound
# receivers (PentHertz/gr-signal-hound), matching RF-Swift-images'
# grsignalhound_Receiver_grmod_install. It builds the BB, SP, SM and VSG series
# blocks against the Signal Hound device APIs.
#
# Upstream lib/CMakeLists.txt link-lists the four device libraries by their
# absolute install path (/usr/local/lib/lib*_api.so, where the SDK installer
# drops them) and does not add the SDK include directory. We rewrite those four
# paths to the Nix signalhound-sdk out and add its headers to the compiler
# search path. The *_api.so libraries reach the radios through libusb, so no
# FTDI D2XX runtime library is needed for these blocks (unlike the SDK's
# tg_series, which gr-signal-hound does not build).
#
# Linux only (x86_64 + aarch64): the SDK ships .so libraries for those, and the
# absolute-path rewrite below is written for the Linux .so layout. On the SDK's
# aarch64-darwin the libraries are .dylib, so this module stays Linux-scoped,
# which also matches the images.
{ lib, fetchFromGitHub, gnuradioPackages, cmake, pkg-config
, boost, spdlog, gmp, volk, signalhound-sdk, python3Packages }:

gnuradioPackages.mkDerivation {
  pname = "gr-signal-hound";
  version = "unstable-penthertz";

  src = fetchFromGitHub {
    owner = "PentHertz";
    repo = "gr-signal-hound";
    rev = "383a799c2940486f98124f47086f7861b9ba53b7";
    hash = "sha256-SwutQ5S2iEYAIEUGkgssYxoaQ/1JZdWlwI5b5TVULII=";
  };

  # Point the hard-coded /usr/local/lib device libraries at the Nix SDK out.
  postPatch = ''
    substituteInPlace lib/CMakeLists.txt \
      --replace-fail "/usr/local/lib/libbb_api.so"  "${signalhound-sdk}/lib/libbb_api.so" \
      --replace-fail "/usr/local/lib/libsp_api.so"  "${signalhound-sdk}/lib/libsp_api.so" \
      --replace-fail "/usr/local/lib/libsm_api.so"  "${signalhound-sdk}/lib/libsm_api.so" \
      --replace-fail "/usr/local/lib/libvsg_api.so" "${signalhound-sdk}/lib/libvsg_api.so"
  '';

  nativeBuildInputs = [ cmake pkg-config python3Packages.pybind11 ];
  buildInputs = [ boost spdlog gmp volk signalhound-sdk python3Packages.numpy ];

  # The block sources #include the SDK headers (bb_api.h, ...) directly; the
  # upstream CMake relied on /usr/local/include being a default search path.
  env.NIX_CFLAGS_COMPILE = "-I${signalhound-sdk}/include";

  cmakeFlags = [ "-DCMAKE_POLICY_VERSION_MINIMUM=3.5" ];

  meta = {
    description = "GNU Radio OOT source blocks for Signal Hound receivers (PentHertz fork)";
    homepage = "https://github.com/PentHertz/gr-signal-hound";
    license = lib.licenses.gpl3Plus;
    platforms = [ "x86_64-linux" "aarch64-linux" ];
  };
}
