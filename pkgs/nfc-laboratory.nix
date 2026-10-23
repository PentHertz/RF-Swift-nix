# nfc-laboratory: NFC signal sniffer/decoder + logic analyzer GUI (josevcm). Qt6
# desktop app; decodes NFC-A/B/F/V from an SDR (RTL-SDR/HackRF/AirSpy/HydraSDR)
# or a logic capture. Built the way RF Swift builds it (the nfc-lab target).
{ lib, stdenv, fetchFromGitHub, cmake, pkg-config, qt6
, libusb1, rtl-sdr, hackrf, airspy, libhydrasdr }:

stdenv.mkDerivation {
  pname = "nfc-laboratory";
  version = "3-unstable-2026-09-20";

  src = fetchFromGitHub {
    owner = "josevcm";
    repo = "nfc-laboratory";
    rev = "79d1bedf02acf13e597cbfa9d61ddd96c2b4df2e";
    hash = "sha256-jYsuD8b+TyZGJTuegnMZLtZYwG4N7j7ZNoyh9G9zrDI=";
  };

  nativeBuildInputs = [ cmake pkg-config qt6.wrapQtAppsHook ];
  buildInputs = [
    qt6.qtbase libusb1 rtl-sdr hackrf airspy libhydrasdr
  ];

  cmakeFlags = [ "-DCMAKE_BUILD_TYPE=Release" "-DCMAKE_POLICY_VERSION_MINIMUM=3.5" ];
  env.NIX_CFLAGS_COMPILE = "-Wno-error";

  # Build only the GUI target (matches RF Swift's recipe).
  ninjaFlags = [ "nfc-lab" ];
  makeFlags = [ "nfc-lab" ];

  installPhase = ''
    runHook preInstall
    mkdir -p $out/bin $out/share/nfc-lab
    bin=$(find . -name nfc-lab -type f -perm -u+x | head -1)
    install -Dm755 "$bin" $out/bin/nfc-lab
    # Ship the decoder firmware and sample captures the app expects.
    cp -r ../dat/firmware $out/share/nfc-lab/ 2>/dev/null || true
    cp -r ../wav $out/share/nfc-lab/ 2>/dev/null || true
    runHook postInstall
  '';

  meta = {
    description = "NFC signal sniffer and protocol decoder with a Qt logic-analyzer GUI";
    homepage = "https://github.com/josevcm/nfc-laboratory";
    license = lib.licenses.gpl3Plus;
    platforms = [ "x86_64-linux" ];
    mainProgram = "nfc-lab";
  };
}
