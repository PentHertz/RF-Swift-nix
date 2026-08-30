# nmapAutomator (21y4d/nmapAutomator): a single Bash script that chains Nmap
# scans into recon/enumeration follow-ups. Matches RF-Swift-images'
# nmapautomator_soft_install. Packaged as the script with the tools it calls put
# on PATH; tools absent from nixpkgs are skipped (the network environment
# supplies the rest of the recon toolchain).
{ lib, stdenv, fetchFromGitHub, makeWrapper, coreutils, gnugrep, gnused, gawk
, nmap
, nikto ? null, gobuster ? null, ffuf ? null, wpscan ? null, smbmap ? null
, samba ? null, sslscan ? null, dnsrecon ? null, dnsutils ? null, whatweb ? null
, droopescan ? null, joomscan ? null, enum4linux-ng ? null, onesixtyone ? null
, snmp ? null, curl ? null }:

stdenv.mkDerivation {
  pname = "nmapautomator";
  version = "unstable-2026-08-30";

  src = fetchFromGitHub {
    owner = "21y4d";
    repo = "nmapAutomator";
    rev = "c5e15de8429c78aa5923010145dfac0996aba9e1";
    hash = "sha256-HwBvhFvGVY5q0C62XjNalQUaX7y24B1Vt8UqAIHp8/g=";
  };

  nativeBuildInputs = [ makeWrapper ];
  dontBuild = true;

  installPhase = ''
    runHook preInstall
    install -Dm755 nmapAutomator.sh $out/bin/nmapAutomator
    wrapProgram $out/bin/nmapAutomator \
      --prefix PATH : ${lib.makeBinPath (lib.filter (x: let r = builtins.tryEval (x != null && lib.isDerivation x); in r.success && r.value) [
        nmap nikto gobuster ffuf wpscan smbmap samba sslscan dnsrecon dnsutils
        whatweb droopescan joomscan enum4linux-ng onesixtyone snmp curl
        coreutils gnugrep gnused gawk
      ])}
    runHook postInstall
  '';

  meta = {
    description = "Nmap automation script chaining scans into recon and enumeration";
    homepage = "https://github.com/21y4d/nmapAutomator";
    license = lib.licenses.gpl3Only;
    platforms = lib.platforms.linux;
    mainProgram = "nmapAutomator";
  };
}
