# libacars: decoding library for ACARS message applications.
# Dependency of dumpvdl2 and dumphfdl.
{ lib, stdenv, fetchFromGitHub, cmake, pkg-config, libxml2, zlib, sqlite, jansson }:

stdenv.mkDerivation rec {
  pname = "libacars";
  version = "2.2.0";

  src = fetchFromGitHub {
    owner = "szpajder";
    repo = "libacars";
    rev = "v${version}";
    # Build once, then replace with the hash Nix prints.
    hash = "sha256-2n1tuKti8Zn5UzQHmRdvW5Q+x4CXS9QuPHFQ+DFriiE=";
  };

  nativeBuildInputs = [ cmake pkg-config ];
  buildInputs = [ libxml2 zlib sqlite jansson ];

  # -DCMAKE_POLICY_VERSION_MINIMUM: this project declares an ancient
  #   cmake_minimum_required; CMake 4 dropped compatibility below 3.5.
  # -DCMAKE_INSTALL_LIBDIR=lib: keep it relative so the generated .pc file does
  #   not end up with a `//nix/store` double slash (nixpkgs issue #144170).
  cmakeFlags = [
    "-DCMAKE_POLICY_VERSION_MINIMUM=3.5"
    "-DCMAKE_INSTALL_LIBDIR=lib"
    "-DCMAKE_INSTALL_INCLUDEDIR=include"
  ];

  meta = {
    description = "Library for decoding the contents of ACARS messages";
    homepage = "https://github.com/szpajder/libacars";
    license = lib.licenses.mit;
    platforms = lib.platforms.unix;
  };
}
