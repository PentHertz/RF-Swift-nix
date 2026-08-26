# Nordic nRF Sniffer for Bluetooth LE: the host-side Wireshark extcap capture
# plugin (nrf_sniffer_ble.py + SnifferAPI) plus the dongle firmware. Same Nordic
# download RF Swift uses. Flash the bundled firmware to an nRF52 dongle; the
# extcap plugin then feeds live BLE captures into Wireshark.
{ lib, stdenv, fetchurl, unzip, makeWrapper, python3 }:

let
  pyEnv = python3.withPackages (ps: with ps; [ pyserial ]);
in
stdenv.mkDerivation {
  pname = "nordic-nrf-sniffer";
  version = "4.1.1";

  src = fetchurl {
    url = "https://nsscprodmedia.blob.core.windows.net/prod/software-and-other-downloads/desktop-software/nrf-sniffer/sw/nrf_sniffer_for_bluetooth_le_4.1.1.zip";
    hash = "sha256-JlAkR3QjRs0LDFl1ZLEqYhhZ/9StBcApBpxPoi3t3UA=";
  };

  nativeBuildInputs = [ unzip makeWrapper ];
  dontBuild = true;
  unpackPhase = ''unzip -q "$src" -d src'';

  installPhase = ''
    runHook preInstall
    mkdir -p $out/share/nordic-nrf-sniffer $out/bin $out/lib/wireshark/extcap
    cp -r src/* $out/share/nordic-nrf-sniffer/
    script=$(find $out/share/nordic-nrf-sniffer -name nrf_sniffer_ble.py | head -1)
    scriptdir=$(dirname "$script")
    chmod +x "$script"
    makeWrapper ${pyEnv}/bin/python3 $out/bin/nrf-sniffer-ble \
      --add-flags "$script" \
      --chdir "$scriptdir" \
      --prefix PYTHONPATH : "$scriptdir"
    # Expose as a Wireshark extcap plugin too.
    ln -s $out/bin/nrf-sniffer-ble $out/lib/wireshark/extcap/nrf_sniffer_ble.py
    runHook postInstall
  '';

  meta = {
    description = "Nordic nRF Sniffer for Bluetooth LE (Wireshark extcap plugin + dongle firmware)";
    homepage = "https://www.nordicsemi.com/Products/Development-tools/nRF-Sniffer-for-Bluetooth-LE";
    license = lib.licenses.unfree;
    platforms = [ "x86_64-linux" ];
    mainProgram = "nrf-sniffer-ble";
  };
}
