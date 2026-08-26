# turbofec: 3GPP LTE turbo/convolutional coder library (zlinwei fork). Not in
# nixpkgs; needed by gr-flarm and gr-droneid. Autotools build.
{ lib, stdenv, fetchFromGitHub, autoreconfHook, pkg-config }:

stdenv.mkDerivation {
  pname = "turbofec";
  version = "unstable-2020";

  src = fetchFromGitHub {
    owner = "zlinwei";
    repo = "turbofec";
    rev = "d871dd1a317b3c822d807f5921f1106629d6e117";
    hash = "sha256-ldrYi8QuJmtna5g1Ga4lKCijxuVMjVJ9qA5dbCJckSo=";
  };

  nativeBuildInputs = [ autoreconfHook pkg-config ];
  # turbofec's SIMD kernels use SSE4.1 and AVX2 intrinsics; without the ISA flags
  # gcc-15 refuses to inline them ("target specific option mismatch"). This makes
  # the x86_64 build require an AVX2-capable CPU at runtime, which matches the
  # amd64 target RF Swift ships this on.
  env.NIX_CFLAGS_COMPILE = "-msse4.1 -mavx2";

  meta = {
    description = "3GPP LTE turbo/convolutional coder library";
    homepage = "https://github.com/zlinwei/turbofec";
    license = lib.licenses.gpl2Plus;
    platforms = lib.platforms.linux;
  };
}
