{ lib, python3Packages, fetchFromGitHub, makeWrapper }:
let pick = names: lib.filter (x: x != null) (map (n: python3Packages.${n} or null) names);
    deps = pick [ "requests" "beautifulsoup4" "dnspython" "aiohttp" "aiodns" "psycopg2" "tld" "ipwhois" "lxml" "icalendar" ];
in python3Packages.buildPythonApplication {
  pname = "finalrecon"; version = "unstable"; format = "other";
  src = fetchFromGitHub { owner = "thewhiteh4t"; repo = "FinalRecon"; rev = "master"; hash = "sha256-4iNvV+u5sSh1y0FL1vvlGjWRwgY8dOibfjdmdyGAPak="; };
  nativeBuildInputs = [ makeWrapper ];
  propagatedBuildInputs = deps;
  dontCheckRuntimeDeps = true; doCheck = false;
  installPhase = ''
    runHook preInstall
    mkdir -p $out/share/finalrecon $out/bin
    cp -r . $out/share/finalrecon/
    makeWrapper ${python3Packages.python.interpreter} $out/bin/finalrecon \
      --add-flags "$out/share/finalrecon/finalrecon.py" \
      --prefix PYTHONPATH : "$out/share/finalrecon:$PYTHONPATH" \
      --chdir "$out/share/finalrecon"
    runHook postInstall
  '';
  meta = { description = "The Last Web Recon Tool You'll Need"; homepage = "https://github.com/thewhiteh4t/FinalRecon"; license = lib.licenses.mit; mainProgram = "finalrecon"; };
}
