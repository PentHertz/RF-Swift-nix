# SubEnum (FlUxIuS/SubEnum): a Bash subdomain-enumeration orchestrator that
# aggregates several passive/active sources. Matches RF-Swift-images'
# subenum_soft_install. Packaged as the script with its source tools on PATH
# (missing ones skipped; the network environment provides the recon toolchain).
{ lib, stdenv, fetchFromGitHub, makeWrapper, coreutils, gnugrep, gnused, gawk
, curl
, subfinder ? null, amass ? null, assetfinder ? null, findomain ? null
, httprobe ? null, httpx ? null, anew ? null, figlet ? null }:

stdenv.mkDerivation {
  pname = "subenum";
  version = "unstable-2026-08-30";

  src = fetchFromGitHub {
    owner = "FlUxIuS";
    repo = "SubEnum";
    rev = "87e1d0ead077153e135b4538aa47f26f7c093d63";
    hash = "sha256-y/4tihi8Iubwk3CmcUfrPFsCLzPkWnsbm8mlpBqimtA=";
  };

  nativeBuildInputs = [ makeWrapper ];
  dontBuild = true;

  installPhase = ''
    runHook preInstall
    install -Dm755 subenum.sh $out/bin/subenum
    wrapProgram $out/bin/subenum \
      --prefix PATH : ${lib.makeBinPath (lib.filter (x: let r = builtins.tryEval (x != null && lib.isDerivation x); in r.success && r.value) [
        subfinder amass assetfinder findomain httprobe httpx anew figlet curl
        coreutils gnugrep gnused gawk
      ])}
    runHook postInstall
  '';

  meta = {
    description = "Bash subdomain-enumeration orchestrator (SubEnum)";
    homepage = "https://github.com/FlUxIuS/SubEnum";
    license = lib.licenses.gpl3Only;
    platforms = lib.platforms.linux;
    mainProgram = "subenum";
  };
}
