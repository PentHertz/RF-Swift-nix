# waving-z: Z-Wave frame encoder/decoder for SDR I/Q streams (baol). Matches
# RF-Swift-images' wavingz_sdr_soft_install. Builds two tools, wave-in (decode)
# and wave-out (encode); CMake, needs only Boost.program_options.
{ lib, stdenv, fetchFromGitHub, cmake, boost }:

stdenv.mkDerivation {
  pname = "waving-z";
  version = "unstable-2019";

  src = fetchFromGitHub {
    owner = "baol";
    repo = "waving-z";
    rev = "99f3e6ba3d6f338ce79f81171fccb44e12cc7c48";
    hash = "sha256-Z/+/h/K78fW4F5aJOAfzaZABwozRNpErXDZ0JSeWdNE=";
  };

  nativeBuildInputs = [ cmake ];
  buildInputs = [ boost ];
  cmakeFlags = [ "-DCMAKE_POLICY_VERSION_MINIMUM=3.5" ];

  # Upstream has no install target; the binaries land in the build dir.
  installPhase = ''
    runHook preInstall
    install -Dm755 wave-in $out/bin/wave-in
    install -Dm755 wave-out $out/bin/wave-out
    runHook postInstall
  '';

  meta = {
    description = "Z-Wave SDR frame decoder (wave-in) and encoder (wave-out)";
    homepage = "https://github.com/baol/waving-z";
    license = lib.licenses.mit;
    platforms = lib.platforms.unix;
  };
}
