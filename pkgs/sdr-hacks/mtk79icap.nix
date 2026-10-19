# Mtk79ICAP (MtkWifiRev): an MT7921AU/MT7961 USB Wi-Fi stick as a SoapySDR
# I/Q source (driver=mt7921), through a fork of the mt7921u kernel driver and
# a patched Wi-Fi firmware. Matches RF-Swift-images' mtk79icap_sdrhacks_install
# (sdr_hacks): the user-space side only.
#
#   * SoapyMT7921 (lib/SoapySDR/modules*), found by every tool of the
#     environment through the profile's SOAPY_SDR_PLUGIN_PATH, and mt7921iq_rx.
#   * mt7961-iq-fw-v65: builds the patched WIFI_RAM_CODE_MT7961_1.bin from the
#     user's own stock linux-firmware copy (it carries only the changed bytes),
#     to install on the host.
#   * mt7921iq-setup: puts the stick's interface into monitor mode (root, once).
#   * The kernel driver must be built and loaded on the host: its sources are in
#     share/mtk79icap/driver, with the docs.
{ lib, stdenv, fetchFromGitHub, cmake, makeWrapper, soapysdr, python3, zstd
, iw, iproute2, coreutils, gnugrep }:

stdenv.mkDerivation {
  pname = "mtk79icap";
  version = "0-unstable-2026-10-16";

  src = fetchFromGitHub {
    owner = "MtkWifiRev";
    repo = "Mtk79ICAP";
    rev = "38221102d67191cfa129644b002a433afb44dae0";
    hash = "sha256-Em0zTGsmFvoeaHcorNiLjPgZJTyHjQTDpSJ8knKZEA8=";
  };

  # SoapyMT7921 pulls in libmt7921iq and mt7921iq_rx as a subdirectory;
  # libmt7921iq includes driver/mt7921/iqstream_ioctl.h, so the whole tree is
  # the source.
  cmakeDir = "../userspace/SoapyMT7921";

  nativeBuildInputs = [ cmake makeWrapper ];
  buildInputs = [ soapysdr ];

  postInstall = ''
    install -Dm644 $src/userspace/udev/99-mt7921-iq.rules -t $out/lib/udev/rules.d
    install -Dm755 $src/firmware/mt7961-iq-fw-v65.py $out/libexec/mtk79icap/mt7961-iq-fw-v65.py
    makeWrapper ${python3.interpreter} $out/bin/mt7961-iq-fw-v65 \
      --add-flags $out/libexec/mtk79icap/mt7961-iq-fw-v65.py \
      --prefix PATH : ${lib.makeBinPath [ zstd ]}
    install -Dm755 $src/userspace/mt7921iq-setup.sh $out/libexec/mtk79icap/mt7921iq-setup.sh
    makeWrapper $out/libexec/mtk79icap/mt7921iq-setup.sh $out/bin/mt7921iq-setup \
      --prefix PATH : ${lib.makeBinPath [ iw iproute2 coreutils gnugrep ]}
    mkdir -p $out/share/mtk79icap
    cp -r $src/driver $src/docs $src/README.md $out/share/mtk79icap/
  '';

  meta = {
    description = "MT7921AU/MT7961 USB Wi-Fi stick as a SoapySDR I/Q source (user-space side)";
    homepage = "https://github.com/MtkWifiRev/Mtk79ICAP";
    license = lib.licenses.mit;
    platforms = lib.platforms.linux;
    mainProgram = "mt7921iq_rx";
  };
}
