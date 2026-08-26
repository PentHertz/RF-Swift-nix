# readsb: ADS-B / Mode-S decoder (wiedehopf fork), the successor to dump1090.
{ lib, stdenv, fetchFromGitHub, pkg-config, git, ncurses, rtl-sdr-osmocom
, libusb1, zlib, zstd, hackrf }:

stdenv.mkDerivation rec {
  pname = "readsb";
  version = "3.14.1623";

  src = fetchFromGitHub {
    owner = "wiedehopf";
    repo = "readsb";
    rev = "v${version}";
    hash = "sha256-1UkOGgtNA6RUaTn/ITZmRPbmzEELZeL2+FreeCn+abM=";
  };

  # readsb's Makefile shells out to git for a version string.
  nativeBuildInputs = [ pkg-config git ];
  buildInputs = [ ncurses rtl-sdr-osmocom libusb1 zlib zstd hackrf ];

  # readsb selects SDR backends via make variables.
  makeFlags = [ "RTLSDR=yes" "HACKRF=yes" "OPTIMIZE=-O2" ];

  # readsb builds with -Werror; gcc 15 promotes new warnings to errors on this
  # older C code, so relax -Werror.
  env.NIX_CFLAGS_COMPILE = "-Wno-error";

  enableParallelBuilding = true;

  installPhase = ''
    runHook preInstall
    install -Dm755 readsb $out/bin/readsb
    install -Dm755 viewadsb $out/bin/viewadsb
    runHook postInstall
  '';

  meta = {
    description = "ADS-B / Mode-S decoder for RTL-SDR, HackRF and other SDRs";
    homepage = "https://github.com/wiedehopf/readsb";
    license = lib.licenses.gpl3Plus;
    platforms = lib.platforms.linux;
    mainProgram = "readsb";
  };
}
