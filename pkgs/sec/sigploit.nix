# SigPloit: telecom signaling (SS7 / GTP / Diameter / SIP) attack framework
# (FlUxIuS fork). The launcher runs on Python 3; the SS7 modules call bundled
# jSS7 JARs (hence the jre).
{ lib, stdenv, fetchFromGitHub, makeWrapper, python3, pysctp, jre }:

let
  pick = names: lib.filter (x: x != null) (map (n: python3.pkgs.${n} or null) names);
  pyEnv = python3.withPackages (ps:
    (pick [ "colorama" "pyfiglet" "termcolor" "configobj" "ipy" "scapy" "requests" ])
    ++ [ pysctp ]);
in
stdenv.mkDerivation {
  pname = "sigploit";
  version = "unstable";

  src = fetchFromGitHub {
    owner = "FlUxIuS";
    repo = "SigPloit";
    rev = "1724855b10d35c467b9711c2e69609671c7cdd5b";
    hash = "sha256-fgfo83zdF1gLXVAvOZFIms8bzMddiV+yi5cDVoAnrSU=";
  };

  nativeBuildInputs = [ makeWrapper ];
  dontBuild = true;

  installPhase = ''
    runHook preInstall
    mkdir -p $out/share/sigploit $out/bin
    cp -r . $out/share/sigploit/
    # The SS7 attack modules invoke bundled Java (jSS7) JARs, so put java on PATH.
    makeWrapper ${pyEnv}/bin/python3 $out/bin/sigploit \
      --add-flags "$out/share/sigploit/sigploit.py" \
      --chdir "$out/share/sigploit" \
      --prefix PATH : "${lib.makeBinPath [ jre ]}" \
      --prefix PYTHONPATH : "$out/share/sigploit"
    runHook postInstall
  '';

  meta = {
    description = "Telecom signaling exploitation framework (SS7 / GTP / Diameter / SIP)";
    homepage = "https://github.com/FlUxIuS/SigPloit";
    license = lib.licenses.mit;
    platforms = lib.platforms.linux;
    mainProgram = "sigploit";
  };
}
