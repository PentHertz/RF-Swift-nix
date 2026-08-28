# turbofec: 3GPP LTE turbo/convolutional coder library (zlinwei fork). Not in
# nixpkgs; needed by gr-flarm and gr-droneid. Autotools build.
{ lib, stdenv, fetchFromGitHub, autoreconfHook, pkg-config, simde }:

let
  # SIMDe is header-only. Its normal package builds the complete upstream test
  # matrix, which is unnecessary when turbofec only includes four headers.
  simdeHeaders = simde.overrideAttrs (_: {
    nativeBuildInputs = [ ];
    dontConfigure = true;
    dontBuild = true;
    installPhase = ''
      mkdir -p $out/include
      cp -r simde $out/include/
    '';
  });
in
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
  buildInputs = lib.optionals (!stdenv.hostPlatform.isx86) [ simdeHeaders ];

  # turbofec only provides x86 SSE decoder kernels. SIMDe supplies compatible
  # implementations on other architectures (notably aarch64) while keeping the
  # public API and the decoder functionality used by gr-flarm/gr-droneid.
  postPatch = lib.optionalString (!stdenv.hostPlatform.isx86) ''
    substituteInPlace src/conv_sse.h src/turbo_sse.h \
      --replace-warn '#include <emmintrin.h>' '#include <simde/x86/sse2.h>' \
      --replace-warn '#include <tmmintrin.h>' '#include <simde/x86/ssse3.h>' \
      --replace-warn '#include <immintrin.h>' '#include <simde/x86/avx2.h>' \
      --replace-warn '#include <smmintrin.h>' '#include <simde/x86/sse4.1.h>'

    # Upstream passes comma-list macros as a single argument to the native
    # intrinsic function. SIMDe exposes the intrinsic as a function-like macro,
    # so add one expansion layer before its argument count is evaluated.
    substituteInPlace src/conv_sse.h src/turbo_sse.h \
      --replace-warn '_mm_set_epi8(' 'RFSWIFT_MM_SET_EPI8(' \
      --replace-warn '_mm_set_epi16(' 'RFSWIFT_MM_SET_EPI16('
    substituteInPlace src/conv_sse.h src/turbo_sse.h \
      --replace-fail $'#ifdef HAVE_SSE3\n#include <stdint.h>' \
        $'#ifdef HAVE_SSE3\n#define RFSWIFT_MM_SET_EPI8_(...) _mm_set_epi8(__VA_ARGS__)\n#define RFSWIFT_MM_SET_EPI8(...) RFSWIFT_MM_SET_EPI8_(__VA_ARGS__)\n#define RFSWIFT_MM_SET_EPI16_(...) _mm_set_epi16(__VA_ARGS__)\n#define RFSWIFT_MM_SET_EPI16(...) RFSWIFT_MM_SET_EPI16_(__VA_ARGS__)\n#include <stdint.h>'
  '';

  # turbofec's SIMD kernels use SSE4.1 and AVX2 intrinsics; without the ISA flags
  # gcc-15 refuses to inline them ("target specific option mismatch"). This makes
  # the x86_64 build require an AVX2-capable CPU at runtime, which matches the
  # amd64 target RF Swift ships this on.
  env.NIX_CFLAGS_COMPILE =
    if stdenv.hostPlatform.isx86 then "-msse4.1 -mavx2"
    else "-DHAVE_SSE3 -DSIMDE_ENABLE_NATIVE_ALIASES";

  meta = {
    description = "3GPP LTE turbo/convolutional coder library";
    homepage = "https://github.com/zlinwei/turbofec";
    license = lib.licenses.gpl2Plus;
    platforms = lib.platforms.linux;
  };
}
