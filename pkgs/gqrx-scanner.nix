# gqrx-scanner: a frequency scanner that drives GQRX over its remote-control API.
{ lib, stdenv, fetchFromGitHub, cmake, pkg-config }:

stdenv.mkDerivation {
  pname = "gqrx-scanner";
  version = "unstable-2023-06-01";

  src = fetchFromGitHub {
    owner = "neural75";
    repo = "gqrx-scanner";
    rev = "master";
    hash = "sha256-fbMk76lmHs6cKcDf3fI9wxK8SK2QW3eSnh1AtNxvwfs=";
  };

  nativeBuildInputs = [ cmake pkg-config ];

  # Older cmake_minimum_required; CMake 4 needs this to stay compatible.
  cmakeFlags = [ "-DCMAKE_POLICY_VERSION_MINIMUM=3.5" ];

  meta = {
    description = "Frequency scanner for GQRX via its remote control protocol";
    homepage = "https://github.com/neural75/gqrx-scanner";
    license = lib.licenses.mit;
    platforms = lib.platforms.unix;
    mainProgram = "gqrx-scanner";
  };
}
