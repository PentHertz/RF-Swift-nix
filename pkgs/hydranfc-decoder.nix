# HydraNFC v2 sniffer decoder: a libsigrokdecode protocol decoder (Python) for
# HydraNFC traces, used from DSView / PulseView / sigrok-cli. RF Swift installs it
# by dropping the decoder into the sigrok decoders directory; here it lands under
# $out/share/libsigrokdecode/decoders so SIGROKDECODE_DIR picks it up.
{ lib, stdenv, fetchFromGitHub }:

stdenv.mkDerivation {
  pname = "hydranfc-sniffer-decoder";
  version = "unstable";

  src = fetchFromGitHub {
    owner = "hydrabus";
    repo = "hydranfc_v2_sniffer_decoder";
    rev = "master";
    hash = "sha256-LqOk/YckEWfEOH2QXMlyEWNRwH91J5Bt+RM5UXNp+eM=";
  };

  dontBuild = true;

  installPhase = ''
    runHook preInstall
    dest=$out/share/libsigrokdecode/decoders/hydranfc_v2_sniffer_decoder
    mkdir -p "$dest"
    cp -r . "$dest/"
    runHook postInstall
  '';

  meta = {
    description = "HydraNFC v2 sniffer protocol decoder for sigrok / DSView / PulseView";
    homepage = "https://github.com/hydrabus/hydranfc_v2_sniffer_decoder";
    license = lib.licenses.gpl3Plus;
    platforms = lib.platforms.linux;
  };
}
