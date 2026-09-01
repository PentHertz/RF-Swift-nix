# BlueSploit: Bluetooth exploitation framework (V33RU). Python CLI.
{ lib, stdenv, fetchFromGitHub, makeWrapper, python3, bluez }:

let
  pick = ps: names: lib.filter (x: x != null) (map (n: ps.${n} or null) names);
  pyEnv = python3.withPackages (ps: pick ps [
    "rich" "cmd2" "scapy" "bleak" "pybluez" "pygobject3" "dbus-python"
  ]);
in
stdenv.mkDerivation {
  pname = "bluesploit";
  version = "unstable";

  src = fetchFromGitHub {
    owner = "V33RU";
    repo = "bluesploit";
    rev = "819e22350471d0f5a4daa9321ad4d03fd6b2c630";
    hash = "sha256-vskiKlqYya9Jmyh72/XcU/4T/1QXDg1o7BPE1cQYpTA=";
  };

  nativeBuildInputs = [ makeWrapper ];
  dontBuild = true;

  installPhase = ''
    runHook preInstall
    mkdir -p $out/share/bluesploit $out/bin
    cp -r . $out/share/bluesploit/
    makeWrapper ${pyEnv}/bin/python3 $out/bin/bluesploit \
      --add-flags "$out/share/bluesploit/bluesploit.py" \
      --chdir "$out/share/bluesploit" \
      --prefix PATH : "${lib.makeBinPath [ bluez ]}" \
      --prefix PYTHONPATH : "$out/share/bluesploit"
    runHook postInstall
  '';

  meta = {
    description = "Bluetooth exploitation framework";
    homepage = "https://github.com/V33RU/bluesploit";
    license = lib.licenses.mit;
    platforms = lib.platforms.linux;
    mainProgram = "bluesploit";
  };
}
