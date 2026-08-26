# Modmobmap (PentHertz): map mobile networks (2G-5G) via modems/phones.
{ lib, python3Packages, fetchFromGitHub }:

let
  pick = names: lib.filter (x: x != null) (map (n: python3Packages.${n} or null) names);
in
python3Packages.buildPythonApplication {
  pname = "modmobmap";
  version = "unstable";
  format = "other"; # plain scripts, no setup.py

  src = fetchFromGitHub {
    owner = "PentHertz";
    repo = "Modmobmap";
    rev = "master";
    hash = "sha256-kYgn20ijgzDAofnEVRKXzAM67V+Pru0RT8c61Fk6I0c=";
  };

  propagatedBuildInputs = pick [ "pyserial" ];
  dontCheckRuntimeDeps = true;
  doCheck = false;

  installPhase = ''
    runHook preInstall
    mkdir -p $out/bin $out/share/modmobmap
    cp -r *.py $out/share/modmobmap/ 2>/dev/null || true
    cat > $out/bin/modmobmap <<EOF
    #!${python3Packages.python.interpreter}
    import runpy, sys, os
    sys.path.insert(0, "$out/share/modmobmap")
    runpy.run_path("$out/share/modmobmap/Modmobmap.py", run_name="__main__")
    EOF
    chmod +x $out/bin/modmobmap
    runHook postInstall
  '';

  meta = {
    description = "Modmobmap: mobile network mapping tool (2G-5G)";
    homepage = "https://github.com/PentHertz/Modmobmap";
    license = lib.licenses.gpl3Plus;
    mainProgram = "modmobmap";
  };
}
