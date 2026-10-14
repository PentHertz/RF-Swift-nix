# IT++ (itpp): C++ library for signal processing and communications. Not in
# nixpkgs; needed by gr-dsd and gr-mixalot. CMake build against BLAS/LAPACK/FFTW.
{ lib, stdenv, fetchurl, cmake, pkg-config, blas, lapack, fftw }:

stdenv.mkDerivation (rec {
  pname = "itpp";
  version = "4.3.1";

  src = fetchurl {
    url = "https://downloads.sourceforge.net/project/itpp/itpp/${version}/itpp-${version}.tar.bz2";
    hash = "sha256-UHF2IcXfte0i+EkvivMrF3dubgZkHf46Oo+CyNNTuHc=";
  };

  nativeBuildInputs = [ cmake pkg-config ];
  buildInputs = [ blas lapack fftw ];

  # IT++ 4.3.1 predates modern compilers; keep it permissive and skip the docs.
  cmakeFlags = [
    "-DITPP_SHARED_LIB=on"
    "-DHTML_DOCS=off"
    "-DCMAKE_POLICY_VERSION_MINIMUM=3.5"
  ] ++ lib.optional stdenv.hostPlatform.isDarwin "-DCMAKE_CXX_STANDARD=14";
  # clang (Darwin) rejects -std=gnu++14 on the C sources these flags also reach
  # (GCC only warns) and has no -fpermissive: give it the C++ standard through
  # CMake instead.
  env.NIX_CFLAGS_COMPILE =
    if stdenv.hostPlatform.isDarwin then "-Wno-error" else "-std=gnu++14 -fpermissive -Wno-error";

  meta = {
    description = "C++ library for signal processing and communications (IT++)";
    homepage = "https://itpp.sourceforge.net/";
    license = lib.licenses.gpl3Plus;
    platforms = lib.platforms.linux;
  };
} // lib.optionalAttrs stdenv.hostPlatform.isDarwin {
  # The source root is on the include path, and on a case-insensitive
  # filesystem (macOS's default APFS) its VERSION file then shadows libc++'s
  # <version> header. CMake never reads it, so rename it there.
  postPatch = ''
    mv VERSION VERSION.txt
  '';
})
