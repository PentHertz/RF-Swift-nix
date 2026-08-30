# webcopilot (FlUxIuS/webcopilot): a Bash automation pipeline that runs
# subdomain enumeration, URL crawling and vulnerability scanning end to end.
# Matches RF-Swift-images' webcopilot_soft_install. Packaged as the `webcopilot`
# script with the tools it drives on PATH (missing ones skipped; the network
# environment supplies the rest).
{ lib, stdenv, fetchFromGitHub, makeWrapper, coreutils, gnugrep, gnused, gawk, jq
, subfinder ? null, assetfinder ? null, amass ? null, findomain ? null
, httpx ? null, anew ? null, gau ? null, waybackurls ? null, nuclei ? null
, dalfox ? null, gf ? null, qsreplace ? null, urldedupe ? null }:

stdenv.mkDerivation {
  pname = "webcopilot";
  version = "unstable-2026-08-30";

  src = fetchFromGitHub {
    owner = "FlUxIuS";
    repo = "webcopilot";
    rev = "8fa42440961a94f044ee79ccff6863c964250033";
    hash = "sha256-mQTP7a6bLLcfVW+NvmJk5sgnQZgrZqz1HvrSz3sfoVk=";
  };

  nativeBuildInputs = [ makeWrapper ];
  dontBuild = true;

  installPhase = ''
    runHook preInstall
    install -Dm755 webcopilot $out/bin/webcopilot
    wrapProgram $out/bin/webcopilot \
      --prefix PATH : ${lib.makeBinPath (lib.filter (x: let r = builtins.tryEval (x != null && lib.isDerivation x); in r.success && r.value) [
        subfinder assetfinder amass findomain httpx anew gau waybackurls nuclei
        dalfox gf qsreplace urldedupe jq coreutils gnugrep gnused gawk
      ])}
    runHook postInstall
  '';

  meta = {
    description = "Automated web-recon and vulnerability-scan pipeline (webcopilot)";
    homepage = "https://github.com/FlUxIuS/webcopilot";
    license = lib.licenses.gpl3Only;
    platforms = lib.platforms.linux;
    mainProgram = "webcopilot";
  };
}
