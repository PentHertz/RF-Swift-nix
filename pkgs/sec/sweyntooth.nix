# SweynTooth (Matheus-Garbelini/sweyntooth_bluetooth_low_energy_attacks): PoC
# scripts for the SweynTooth BLE link-layer/SMP vulnerabilities, driven through
# an nRF52840 dongle flashed with the bundled driver firmware. Matches
# RF-Swift-images' sweyntooth_soft_install (checkout + venv from
# requirements.txt + libs/smp_server built with setup.py).
#
# The checkout goes to share/sweyntooth; `sweyntooth <poc> <serial port>
# <target address>` runs share/sweyntooth/<poc>.py (or extras/<poc>.py) from the
# current directory, with the repo and its bundled libs/ (patched scapy 2.4
# snapshot with the Nordic BLE layers, colorama, timeout_lib) on PYTHONPATH,
# so pcap captures land in ./ and ./logs/ instead of the read-only store.
# `sweyntooth --list` lists the PoCs.
#
# Python: upstream targets Python 2.7 (README/Dockerfile); the image, like this
# package, runs it on Python 3. With the patches below all 26 PoCs import and
# get as far as opening the dongle on Python 3.14, and the 20 link-layer PoCs
# have no Python 2-only code left. The 6 that do link-layer encryption or SMP
# pairing (Telink_zero_ltk_installation, esp32_hci_desync,
# extras/anomaly_unexpected_encryption_start, extras/non_compliance_*
# {data_during_encryption_setup,dhcheck_skip,nonzero_ediv_rand}) still mix str
# and bytes Python 2 style and will fail at that stage; porting them is out of
# scope. (In the image they also lack BLESMPServer: upstream's Makefile has no
# `build` target.)
#
# nrfutil (requirements.txt) is only needed to flash the dongle and is left out:
# the pin has no Python nrfutil, only Nordic's newer unfree `nrfutil`
# (pkgs.nrfutil), which flashes the same zip with
#   nrfutil install nrf5sdk-tools
#   nrfutil nrf5sdk-tools dfu usb-serial -p /dev/ttyACM0 -pkg "$(sweyntooth --firmware)"
{ lib, stdenvNoCC, fetchFromGitHub, python3, python3Packages, runtimeShell }:

let
  version = "unstable-2021-11-23";

  src = fetchFromGitHub {
    owner = "Matheus-Garbelini";
    repo = "sweyntooth_bluetooth_low_energy_attacks";
    rev = "40c985b9a9ff1189ddf278462440b120cf96b196";
    hash = "sha256-CPsQA1Mk317LykI13rAL3T7kfD+6sh87i/c98kP5Zec=";
  };

  # libs/smp_server: the BLESMPServer CPython extension (C/C++ SMP host stack)
  # imported by the pairing/encryption PoCs.
  blesmpserver = python3Packages.buildPythonPackage {
    pname = "blesmpserver";
    version = "1.0.1";
    inherit src;
    sourceRoot = "${src.name}/libs/smp_server";
    pyproject = true;
    build-system = [ python3Packages.setuptools ];
    doCheck = false; # test.py needs scapy from the parent checkout
    pythonImportsCheck = [ "BLESMPServer" ];
  };

  pyEnv = python3.withPackages (ps: [ ps.pyserial ps.pycryptodome ps.six blesmpserver ]);
in
stdenvNoCC.mkDerivation {
  pname = "sweyntooth";
  inherit version src;

  dontBuild = true;

  # The bundled scapy snapshot predates Python 3.12/3.13: its vendored six 1.10
  # has no find_spec (scapy.modules.six.moves imports fail) and themes.py
  # imports the removed cgi module (only for cgi.escape). Two PoCs build their
  # packet with Python 2's str.decode('hex').
  postPatch = ''
    cp ${python3Packages.six}/${python3.sitePackages}/six.py libs/scapy/modules/six.py
    substituteInPlace libs/scapy/themes.py --replace-fail 'import cgi' 'import html as cgi'
    sed -i "s/'\([0-9a-f]*\)'\.decode('hex')/bytes.fromhex('\1')/" \
      DA14580_exploit_att_crash.py DA14680_exploit_silent_overflow.py
    if grep -n "decode('hex')" DA14580_exploit_att_crash.py DA14680_exploit_silent_overflow.py; then exit 1; fi
    # Some extras/ PoCs save captures to <script dir>/../logs; use ./logs like the rest.
    substituteInPlace extras/*.py --replace-quiet "script_folder + '/../logs/" "'logs/"
  '';

  installPhase = ''
    runHook preInstall
    share=$out/share/sweyntooth
    mkdir -p $share $out/bin
    cp -r *.py drivers libs extras captures docs README.md \
      nRF52_driver_firmware.hex nRF52_driver_firmware.zip s140_nrf52_6.1.1_softdevice.hex \
      $share/

    cat > $out/bin/sweyntooth <<EOF
    #!${runtimeShell}
    share=$share
    usage() {
      echo "usage: sweyntooth <poc> [serial port] [target address]   run a SweynTooth PoC"
      echo "       sweyntooth --list                                   list the PoCs"
      echo "       sweyntooth --firmware                               print the nRF52840 dongle firmware (DFU zip)"
      echo "PoCs run from the current directory; captures go to ./ and ./logs/."
    }
    case "\''${1:-}" in
      ""|-h|--help) usage; exit 0 ;;
      --firmware) echo "\$share/nRF52_driver_firmware.zip"; exit 0 ;;
      --list)
        for f in "\$share"/*.py; do basename "\$f" .py; done
        for f in "\$share"/extras/*.py; do echo "extras/\$(basename "\$f" .py)"; done
        exit 0 ;;
    esac
    poc=\''${1%.py}; shift
    if [ -f "\$share/\$poc.py" ]; then script=\$share/\$poc.py
    elif [ -f "\$share/extras/\$poc.py" ]; then script=\$share/extras/\$poc.py
    else echo "sweyntooth: unknown PoC '\$poc' (see sweyntooth --list)" >&2; exit 1
    fi
    mkdir -p logs
    export PYTHONPATH="\$share:\$share/libs\''${PYTHONPATH:+:\$PYTHONPATH}"
    exec ${pyEnv}/bin/python3 "\$script" "\$@"
    EOF
    chmod +x $out/bin/sweyntooth
    runHook postInstall
  '';

  passthru = { inherit blesmpserver; };

  meta = {
    description = "SweynTooth BLE vulnerability PoCs (nRF52840 dongle based)";
    homepage = "https://github.com/Matheus-Garbelini/sweyntooth_bluetooth_low_energy_attacks";
    license = lib.licenses.unfree; # repo has no license (bundles GPL-2.0 scapy, BSD colorama)
    # Ships the prebuilt dongle firmware (nRF52_driver_firmware.*, s140 SoftDevice).
    sourceProvenance = with lib.sourceTypes; [ fromSource binaryFirmware ];
    platforms = lib.platforms.linux;
    mainProgram = "sweyntooth";
  };
}
