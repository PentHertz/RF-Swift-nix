# Fluxion: evil-twin / rogue-AP WPA handshake capture and social-engineering
# framework (FluxionNetwork). Pure Bash; it just needs its attack tools on PATH.
{ lib, stdenv, fetchFromGitHub, makeWrapper
, bash, aircrack-ng, mdk4, hostapd, lighttpd, php, cowpatty, xterm, macchanger
, dsniff, bettercap, nmap, curl, unzip, openssl, iw, iproute2, gawk, coreutils
, util-linux, procps, gnugrep, gnused }:

stdenv.mkDerivation {
  pname = "fluxion";
  version = "6.9-unstable";

  src = fetchFromGitHub {
    owner = "FluxionNetwork";
    repo = "fluxion";
    rev = "cac48e9850fe992502590becaeb83c148873c4f0";
    hash = "sha256-PBYBEqYi1lvTx4TTN3ZoY5t36CuNECAswM1mU6amvqc=";
  };

  nativeBuildInputs = [ makeWrapper ];
  dontBuild = true;

  installPhase = ''
    runHook preInstall
    mkdir -p $out/share/fluxion $out/bin
    cp -r . $out/share/fluxion/
    chmod +x $out/share/fluxion/fluxion.sh
    makeWrapper $out/share/fluxion/fluxion.sh $out/bin/fluxion \
      --chdir "$out/share/fluxion" \
      --prefix PATH : "${lib.makeBinPath [
        bash aircrack-ng mdk4 hostapd lighttpd php cowpatty xterm macchanger
        dsniff bettercap nmap curl unzip openssl iw iproute2 gawk coreutils
        util-linux procps gnugrep gnused
      ]}"
    runHook postInstall
  '';

  meta = {
    description = "Evil-twin WPA/WPA2 handshake capture and rogue-AP attack framework";
    homepage = "https://github.com/FluxionNetwork/fluxion";
    license = lib.licenses.mit;
    platforms = lib.platforms.linux;
    mainProgram = "fluxion";
  };
}
