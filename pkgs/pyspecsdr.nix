# PySpecSDR: terminal (curses) spectrum analyzer / scanner for RTL-SDR and
# SoapySDR devices (xqtr). Matches RF-Swift-images' pyspecsdr_sdr_soft_install.
# Upstream is a set of plain Python modules with no packaging metadata, so we
# install them as-is and expose a `pyspecsdr` launcher on a Python that carries
# its requirements (numpy, scipy, sounddevice, pyrtlsdr, SoapySDR bindings).
{ lib, stdenvNoCC, fetchFromGitHub, python3, makeWrapper }:

let
  py = python3.withPackages (ps: with ps; [ numpy scipy sounddevice pyrtlsdr soapysdr ]);
in
stdenvNoCC.mkDerivation {
  pname = "pyspecsdr";
  version = "unstable-2025";

  src = fetchFromGitHub {
    owner = "xqtr";
    repo = "PySpecSDR";
    rev = "050a0c6bb0efcf4c01b59e4e6b3794e7aaf66697";
    hash = "sha256-Qwzr5eTgsdtwzm+e6Lnghq0zp/FcupVodrUF08G0JdQ=";
  };

  nativeBuildInputs = [ makeWrapper ];
  dontBuild = true;

  installPhase = ''
    runHook preInstall
    mkdir -p $out/share/pyspecsdr $out/bin
    cp -r *.py *.json *.md $out/share/pyspecsdr/
    # The app resolves its sibling modules and config next to the main script;
    # run it from the share dir so relative imports/paths keep working.
    makeWrapper ${py}/bin/python3 $out/bin/pyspecsdr \
      --add-flags "$out/share/pyspecsdr/pyspecsdr.py"
    makeWrapper ${py}/bin/python3 $out/bin/gqrx2pss \
      --add-flags "$out/share/pyspecsdr/gqrx2pss.py"
    runHook postInstall
  '';

  meta = {
    description = "PySpecSDR: terminal spectrum analyzer and scanner for RTL-SDR/SoapySDR devices";
    homepage = "https://github.com/xqtr/PySpecSDR";
    license = lib.licenses.gpl3Plus;
    mainProgram = "pyspecsdr";
    platforms = lib.platforms.unix;
  };
}
