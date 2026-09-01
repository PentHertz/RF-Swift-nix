# RFIDler host CLI (AdamLaurie): the Python control tool for the RFIDler LF RFID
# reader/emulator. RF Swift ships the repo's python/ host tool plus mphidflash for
# flashing the device firmware.
{ lib, python3Packages, fetchFromGitHub, makeWrapper, mphidflash }:

python3Packages.buildPythonApplication {
  pname = "rfidler";
  version = "1.0-unstable";
  format = "setuptools";

  src = fetchFromGitHub {
    owner = "AdamLaurie";
    repo = "RFIDler";
    rev = "7206bf9e1ac8f806bcaa2287dd7093a683d84b2f";
    hash = "sha256-61hv/BZE2Ec3DtP3UDPnaj4PIbsN7DRuJA2M6/da3e8=";
  };

  # The host tool lives under python/ in the repo.
  sourceRoot = "source/python";

  nativeBuildInputs = [ makeWrapper ];
  propagatedBuildInputs = [ python3Packages.pyserial ];
  doCheck = false;

  # Expose mphidflash (firmware flashing) alongside the rfidler CLI.
  postFixup = ''
    wrapProgram $out/bin/rfidler.py --prefix PATH : "${lib.makeBinPath [ mphidflash ]}"
    ln -s $out/bin/rfidler.py $out/bin/rfidler 2>/dev/null || true
  '';

  meta = {
    description = "Host CLI for the RFIDler LF RFID reader/emulator";
    homepage = "https://github.com/AdamLaurie/RFIDler";
    license = lib.licenses.gpl2Plus;
    platforms = [ "x86_64-linux" ];
    mainProgram = "rfidler.py";
  };
}
