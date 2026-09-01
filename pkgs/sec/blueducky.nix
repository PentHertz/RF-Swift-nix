# BlueDucky: unauthenticated Bluetooth HID (CVE-2023-45866) keystroke-injection
# PoC (pentestfunctions).
{ lib, stdenv, fetchFromGitHub, makeWrapper, python3, bluez }:

let
  pick = ps: names: lib.filter (x: x != null) (map (n: ps.${n} or null) names);
  pyEnv = python3.withPackages (ps: pick ps [
    "dbus-python" "pybluez" "pycairo" "pydbus" "pygobject3" "setuptools"
  ]);
in
stdenv.mkDerivation {
  pname = "blueducky";
  version = "unstable";

  src = fetchFromGitHub {
    owner = "pentestfunctions";
    repo = "BlueDucky";
    rev = "8b9715cfc93a2cf58d6b8b0b00fc7de70c3fa3ae";
    hash = "sha256-k1FxPT5a+pRjy9EgwB4zmfHQgc4u23U7YBRhDE80nPI=";
  };

  nativeBuildInputs = [ makeWrapper ];
  dontBuild = true;

  installPhase = ''
    runHook preInstall
    mkdir -p $out/share/blueducky $out/bin
    cp -r . $out/share/blueducky/
    makeWrapper ${pyEnv}/bin/python3 $out/bin/blueducky \
      --add-flags "$out/share/blueducky/BlueDucky.py" \
      --chdir "$out/share/blueducky" \
      --prefix PATH : "${lib.makeBinPath [ bluez ]}" \
      --prefix PYTHONPATH : "$out/share/blueducky"
    runHook postInstall
  '';

  meta = {
    description = "Bluetooth HID keystroke-injection PoC (CVE-2023-45866)";
    homepage = "https://github.com/pentestfunctions/BlueDucky";
    license = lib.licenses.mit;
    platforms = lib.platforms.linux;
    mainProgram = "blueducky";
  };
}
