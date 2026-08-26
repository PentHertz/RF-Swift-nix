# mfdread: MIFARE Classic dump reader/pretty-printer (single Python script).
{ lib, python3Packages, fetchFromGitHub, makeWrapper }:

python3Packages.buildPythonApplication {
  pname = "mfdread";
  version = "unstable";
  format = "other";

  src = fetchFromGitHub {
    owner = "zhovner";
    repo = "mfdread";
    rev = "master";
    hash = "sha256-GAqHR0UcxrAedMOpvsGUYo5ESWEP9WCqznNJrMfMaWE=";
  };

  nativeBuildInputs = [ makeWrapper ];
  propagatedBuildInputs = with python3Packages; [ prettytable bitstring ];
  dontBuild = true;
  doCheck = false;

  installPhase = ''
    runHook preInstall
    mkdir -p $out/share/mfdread $out/bin
    cp mfdread.py $out/share/mfdread/
    makeWrapper ${python3Packages.python.interpreter} $out/bin/mfdread \
      --add-flags "$out/share/mfdread/mfdread.py" \
      --prefix PYTHONPATH : "$PYTHONPATH"
    runHook postInstall
  '';

  meta = {
    description = "Pretty-printer/reader for MIFARE Classic card dumps";
    homepage = "https://github.com/zhovner/mfdread";
    license = lib.licenses.gpl2Plus;
    mainProgram = "mfdread";
  };
}
