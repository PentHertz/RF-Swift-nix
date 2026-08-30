# Breaktooth (FlUxIuS/breaktooth-unofficial): the PoC for the Breaktooth
# attack - abusing Bluetooth BR/EDR power-saving (sniff mode) to hijack a
# session and its link key, then inject HID keystrokes over an emulated
# keyboard (https://breaktooth.dev/). It matches RF-Swift-images'
# breaktooth_soft_install.
#
# Upstream targets Raspberry Pi OS and ships a `requirements.txt` that is a full
# `pip freeze` of a Pi image (arandr, picamera2, RPi.GPIO, sense-hat, ...), none
# of which the tool imports. The real dependencies, from the Makefile's
# install/deps and the scripts' imports, are PyBluez (`bluetooth`), dbus-python,
# PyGObject (`gi`), colorama, pyudev and evdev, plus BlueZ at runtime. The Go
# helper `chg_bt_addr` (cmd/configer) rewrites the adapter BD_ADDR through
# hcitool and uses only the standard library.
{ lib, stdenv, fetchFromGitHub, makeWrapper, python3, go, bluez }:

let
  pick = ps: names: lib.filter (x: x != null) (map (n: ps.${n} or null) names);
  pyEnv = python3.withPackages (ps: pick ps [
    "pybluez" "dbus-python" "pygobject3" "pycairo" "colorama" "pyudev" "evdev" "setuptools"
  ]);
in
stdenv.mkDerivation {
  pname = "breaktooth";
  version = "unstable-2026-02-03";

  src = fetchFromGitHub {
    owner = "FlUxIuS";
    repo = "breaktooth-unofficial";
    rev = "345f16b1010c9a6f909f794c2179632944b610dc";
    hash = "sha256-7aibyWn+jDj/lm3nRV/hc62bUsGlcSnkXrcLrlueXAk=";
  };

  nativeBuildInputs = [ makeWrapper go ];

  # Build the pure-stdlib Go helper offline. Upstream ships no go.mod, so
  # synthesize a trivial one; no modules are fetched.
  buildPhase = ''
    runHook preBuild
    export HOME=$TMPDIR GOCACHE=$TMPDIR/go-cache GOPATH=$TMPDIR/go \
           GOPROXY=off GOFLAGS=-mod=mod GOTOOLCHAIN=local CGO_ENABLED=0
    printf 'module github.com/FlUxIuS/breaktooth-unofficial\ngo 1.21\n' > go.mod
    go build -o chg_bt_addr ./cmd/configer
    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall
    mkdir -p $out/share/breaktooth $out/bin
    cp -r cmd conf Makefile README.md LICENSE $out/share/breaktooth/
    install -Dm755 chg_bt_addr $out/bin/breaktooth-chg-bt-addr

    # The attacker scripts import their sibling `tools.*` package, so they run
    # from cmd/attacker with that directory on PYTHONPATH. Each needs root and
    # BlueZ (hciconfig/hcitool/bluetoothctl) at runtime; the wrappers keep BlueZ
    # on PATH so `sudo breaktooth ...` works.
    wrap() {
      makeWrapper ${pyEnv}/bin/python3 "$out/bin/$1" \
        --add-flags "$out/share/breaktooth/cmd/attacker/$2" \
        --chdir "$out/share/breaktooth/cmd/attacker" \
        --prefix PATH : "${lib.makeBinPath [ bluez ]}" \
        --prefix PYTHONPATH : "$out/share/breaktooth/cmd/attacker"
    }
    wrap breaktooth breaktooth.py
    wrap breaktooth-kb-server boot_kb_server.py
    wrap breaktooth-injector key_stroke_injector.py
    runHook postInstall
  '';

  meta = {
    description = "Breaktooth: Bluetooth BR/EDR power-saving session hijack and HID keystroke injection PoC";
    homepage = "https://github.com/FlUxIuS/breaktooth-unofficial";
    license = lib.licenses.mit;
    platforms = lib.platforms.linux;
    mainProgram = "breaktooth";
  };
}
