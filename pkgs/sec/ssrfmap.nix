# SSRFmap: automatic SSRF fuzzer and exploitation tool.
{ lib, python3Packages, fetchFromGitHub, makeWrapper }:

let
  pick = names: lib.filter (x: x != null) (map (n: python3Packages.${n} or null) names);
in
python3Packages.buildPythonApplication {
  pname = "ssrfmap";
  version = "unstable";
  format = "other";

  src = fetchFromGitHub {
    owner = "swisskyrepo";
    repo = "SSRFmap";
    rev = "master";
    hash = "sha256-PM1ZvebrU09d1ug53wm+CeKh0jBC16Zd4KnFOfHEirI=";
  };

  nativeBuildInputs = [ makeWrapper ];
  propagatedBuildInputs = pick [ "requests" "terminaltables" "colorama" "pysocks" "dnspython" ];
  dontBuild = true;
  doCheck = false;

  installPhase = ''
    runHook preInstall
    mkdir -p $out/share/ssrfmap $out/bin
    cp -r . $out/share/ssrfmap/
    makeWrapper ${python3Packages.python.interpreter} $out/bin/ssrfmap \
      --add-flags "$out/share/ssrfmap/ssrfmap.py" \
      --chdir "$out/share/ssrfmap" \
      --prefix PYTHONPATH : "$out/share/ssrfmap:$PYTHONPATH"
    runHook postInstall
  '';

  meta = {
    description = "Automatic SSRF fuzzer and exploitation tool";
    homepage = "https://github.com/swisskyrepo/SSRFmap";
    license = lib.licenses.gpl3Plus;
    mainProgram = "ssrfmap";
  };
}
