# retrogram-soapysdr: a lightweight ncurses spectrum analyzer over SoapySDR.
{ lib, stdenv, fetchFromGitHub, pkg-config, soapysdr-with-plugins, boost, ncurses }:

stdenv.mkDerivation {
  pname = "retrogram-soapysdr";
  version = "unstable-2023-01-01";

  src = fetchFromGitHub {
    owner = "r4d10n";
    repo = "retrogram-soapysdr";
    rev = "master";
    hash = "sha256-zIQgTnqAaR01ff4iVIAXjYnTyEjqx7Ao7k024tvuvpo=";
  };

  nativeBuildInputs = [ pkg-config ];
  buildInputs = [ soapysdr-with-plugins boost ncurses ];

  # Upstream ships a plain Makefile that hardcodes the binary; install by hand.
  installPhase = ''
    runHook preInstall
    install -Dm755 retrogram-soapysdr $out/bin/retrogram-soapysdr
    runHook postInstall
  '';

  meta = {
    description = "Ncurses spectrum analyzer for SoapySDR devices";
    homepage = "https://github.com/r4d10n/retrogram-soapysdr";
    license = lib.licenses.gpl3Plus;
    platforms = lib.platforms.linux;
    mainProgram = "retrogram-soapysdr";
  };
}
