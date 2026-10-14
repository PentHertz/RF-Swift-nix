# Modmobmap (PentHertz): map mobile networks (2G-5G) via modems/phones.
{ lib, python3Packages, fetchFromGitHub, makeWrapper }:

let
  pick = names: lib.filter (x: x != null) (map (n: python3Packages.${n} or null) names);
  deps = pick [ "pyserial" ];
in
python3Packages.buildPythonApplication {
  pname = "modmobmap";
  version = "unstable";
  format = "other"; # plain scripts, no setup.py

  src = fetchFromGitHub {
    owner = "PentHertz";
    repo = "Modmobmap";
    rev = "02a0b1e53138b944f09fa046ca91f83440177816";
    hash = "sha256-kYgn20ijgzDAofnEVRKXzAM67V+Pru0RT8c61Fk6I0c=";
  };

  nativeBuildInputs = [ makeWrapper ];
  propagatedBuildInputs = deps;
  dontCheckRuntimeDeps = true;
  doCheck = false;

  # The operator cache is read and written as cache/operators.json relative to
  # the working directory (upstream runs from its checkout). Keep it in a
  # per-user cache dir instead, seeded from the repo's sample on first use.
  postPatch = ''
    substituteInPlace utils/logprocess.py \
      --replace-fail "from __future__ import print_function" $'from __future__ import print_function\nimport os' \
      --replace-fail "open('cache/operators.json'" "open(os.path.join(os.environ['MODMOBMAP_CACHE_DIR'], 'operators.json')"
  '';

  # The entry point is modmobmap.py (lowercase) and imports the core/, engines/
  # and utils/ packages, so install the whole tree, not just the top-level .py.
  installPhase = ''
    runHook preInstall
    mkdir -p $out/share/modmobmap
    cp -r __init__.py modmobmap.py core engines utils thirdparty samples cache $out/share/modmobmap/
    makeWrapper ${python3Packages.python.interpreter} $out/bin/modmobmap \
      --add-flags "$out/share/modmobmap/modmobmap.py" \
      --prefix PYTHONPATH : "$out/share/modmobmap:${python3Packages.makePythonPath deps}" \
      --run 'export MODMOBMAP_CACHE_DIR="''${MODMOBMAP_CACHE_DIR:-''${XDG_CACHE_HOME:-$HOME/.cache}/modmobmap}"' \
      --run 'mkdir -p "$MODMOBMAP_CACHE_DIR"' \
      --run '[ -e "$MODMOBMAP_CACHE_DIR/operators.json" ] || install -m 644 '"$out"'/share/modmobmap/cache/operators.json "$MODMOBMAP_CACHE_DIR/"'
    runHook postInstall
  '';

  meta = {
    description = "Modmobmap: mobile network mapping tool (2G-5G)";
    homepage = "https://github.com/PentHertz/Modmobmap";
    license = lib.licenses.gpl3Plus;
    mainProgram = "modmobmap";
  };
}
