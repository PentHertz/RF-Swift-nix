# LR2021-SDR (SAMS0N1TE): the Semtech LR2021 LoRa transceiver, on an
# ESP32-P4 board, as an I/Q SDR. Matches RF-Swift-images'
# lr2021sdr_sdrhacks_install (sdr_hacks): the host library and tools (lriq_tool,
# lr2021_lab, liblriq, liblr2021_iq), the Python TX/decode helpers, and the
# prebuilt ESP32-P4 capture firmware of the same release, flashed with:
#
#   esptool --chip esp32p4 --port /dev/ttyACM0 write-flash \
#     0x2000 bootloader.bin 0x8000 partition-table.bin 0x10000 lr2021_capture.bin
#
# from share/lr2021-sdr/firmware.
{ lib, stdenv, fetchFromGitHub, fetchzip, cmake, makeWrapper, python3 }:

let
  version = "0.3.0";
  firmware = fetchzip {
    url = "https://github.com/SAMS0N1TE/lr2021-sdr/releases/download/v${version}/lr2021-sdr-esp32p4.zip";
    hash = "sha256-aeJ81TvnmVF1t/5eWl3W9szr/cWBC6Qe742RD27S+NI=";
    stripRoot = false;
  };
  python = python3.withPackages (ps: [ ps.numpy ]);
  pythonTools = [
    "lr2021_make_p25" "lr2021_make_temperature" "lr2021_make_apsk" "lr2021_tx_upload"
    "lr2021_decode_p25_capture" "lr2021_decode_temperature_capture"
  ];
in
stdenv.mkDerivation {
  pname = "lr2021-sdr";
  inherit version;

  src = fetchFromGitHub {
    owner = "SAMS0N1TE";
    repo = "lr2021-sdr";
    rev = "v${version}";
    # research/ is ~88 MB of sample captures; the tests only read the TX
    # payload includes and the P25 voice inputs.
    postFetch = ''
      find $out/research -type f ! -path '*/tx-payload/*.inc' ! -path '*/tx-p25/inputs/*' -delete
      find $out/research -type d -empty -delete
    '';
    hash = "sha256-Xwftx9Qvix/1E0jQcV5rEZwSb1jERp9mUnfTv5w5Jaw=";
  };

  # -Werror against the compilers upstream tested with only.
  postPatch = ''
    substituteInPlace CMakeLists.txt --replace-quiet " -Werror" ""
  '';

  nativeBuildInputs = [ cmake makeWrapper ];
  # The test suite also runs the Python generators; numpy is all they need.
  nativeCheckInputs = [ python ];
  doCheck = true;

  postInstall = ''
    for t in ${toString pythonTools}; do
      install -Dm644 $src/tools/$t.py $out/libexec/lr2021-sdr/$t.py
      makeWrapper ${python.interpreter} $out/bin/$t --add-flags $out/libexec/lr2021-sdr/$t.py
    done
    mkdir -p $out/share/lr2021-sdr
    cp -r ${firmware} $out/share/lr2021-sdr/firmware
    cp -r $src/docs $src/README.md $out/share/lr2021-sdr/
  '';

  meta = {
    description = "Semtech LR2021 LoRa transceiver as an I/Q SDR: host tools and ESP32-P4 firmware";
    homepage = "https://github.com/SAMS0N1TE/lr2021-sdr";
    license = lib.licenses.gpl3Only;
    platforms = lib.platforms.linux ++ lib.platforms.darwin;
    mainProgram = "lriq_tool";
  };
}
