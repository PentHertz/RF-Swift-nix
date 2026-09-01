# SpiderFoot: OSINT automation. Not in nixpkgs; Python app run as `sf.py`.
{ lib, python3Packages, fetchFromGitHub, makeWrapper }:

let
  pick = names: lib.filter (x: x != null) (map (n: python3Packages.${n} or null) names);
  deps = pick [
    "requests" "lxml" "netaddr" "dnspython" "beautifulsoup4" "cherrypy"
    "cherrypy-cors" "mako" "pypdf" "openpyxl" "python-docx" "python-pptx"
    "exifread" "phonenumbers" "pysocks" "secure" "networkx" "adblockparser"
    "cryptography" "publicsuffixlist" "pyyaml" "python-whois"
  ];
in
python3Packages.buildPythonApplication {
  pname = "spiderfoot";
  version = "4.0";
  format = "other";

  src = fetchFromGitHub {
    owner = "smicallef";
    repo = "spiderfoot";
    rev = "0f815a203afebf05c98b605dba5cf0475a0ee5fd";
    hash = "sha256-LsaLgz+tZyTUBLxa7FoJusGgMa3sgLUMZMVPZUpvWdY=";
  };

  nativeBuildInputs = [ makeWrapper ];
  propagatedBuildInputs = deps;
  dontCheckRuntimeDeps = true;
  doCheck = false;

  installPhase = ''
    runHook preInstall
    mkdir -p $out/share/spiderfoot $out/bin
    cp -r . $out/share/spiderfoot/
    for entry in sf sfcli; do
      makeWrapper ${python3Packages.python.interpreter} $out/bin/$entry \
        --add-flags "$out/share/spiderfoot/$entry.py" \
        --prefix PYTHONPATH : "$out/share/spiderfoot:$PYTHONPATH"
    done
    runHook postInstall
  '';

  meta = {
    description = "SpiderFoot: open-source OSINT automation";
    homepage = "https://github.com/smicallef/spiderfoot";
    license = lib.licenses.mit;
    mainProgram = "sf";
  };
}
