# libspectranstream: streaming client library for Aaronia SPECTRAN V6 (hb9fxq).
# Not in nixpkgs; needed by gr-aaronia_rtsa. CMake build. Ensures the public
# header (spectranstream.h) is installed so downstream modules can include it.
{ lib, stdenv, fetchFromGitHub, cmake, pkg-config, rapidjson, curl }:

stdenv.mkDerivation {
  pname = "libspectranstream";
  version = "unstable";

  src = fetchFromGitHub {
    owner = "hb9fxq";
    repo = "libspectranstream";
    rev = "d50791e5de02d49132e62314909dd18c8d871b57";
    hash = "sha256-nXVjtWRYeiQG/Oz518bHMm7nztzDWmdgG2J8s6fwBao=";
  };

  nativeBuildInputs = [ cmake pkg-config ];
  buildInputs = [ rapidjson curl ];
  cmakeFlags = [
    "-DCMAKE_POLICY_VERSION_MINIMUM=3.5"
    "-DRapidJSON_DIR=${rapidjson}/lib/cmake/RapidJSON"
  ];

  # Upstream builds a demo app too; only the library + header matter here. Make
  # sure the header lands in $out/include even if CMake install skips it.
  postInstall = ''
    install -Dm644 ../lib/spectranstream.h $out/include/spectranstream.h
    install -Dm644 ../lib/ArbitraryLengthCircularBuffer.h $out/include/ArbitraryLengthCircularBuffer.h 2>/dev/null || true
  '';

  meta = {
    description = "Streaming client library for Aaronia SPECTRAN V6";
    homepage = "https://github.com/hb9fxq/libspectranstream";
    license = lib.licenses.mit;
    platforms = lib.platforms.linux;
  };
}
