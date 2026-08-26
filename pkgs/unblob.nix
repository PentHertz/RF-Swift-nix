# unblob: extract-everything firmware/archive analyzer (onekey-sec). nixpkgs
# marks it (and its transitive `fs` dep, pulled in by pyfatfs) unsupported on
# Python 3.14, but `fs` actually works there. Rebuild `fs` and `pyfatfs` without
# the interpreter guard and rebuild unblob against them.
{ lib, python3Packages, unblob }:

let
  fsFixed = python3Packages.fs.overridePythonAttrs (o: {
    disabled = false;
    doCheck = false;
    dontCheckRuntimeDeps = true;
    # fs 2.4.16's __init__ opens with a legacy namespace-package shim,
    # `__import__("pkg_resources").declare_namespace(__name__)`. fs is a single
    # regular distribution here (not split across packages), so the shim does
    # nothing useful, yet it forces a runtime import of pkg_resources. Under
    # Python 3.14 setuptools/pkg_resources is no longer implicitly present, so
    # `import fs` -- and thus the import check and every downstream user -- dies
    # with ModuleNotFoundError. Drop the shim line entirely.
    # fs 2.4.16 predates setuptools 81, which deleted pkg_resources outright, so
    # every pkg_resources use has to go. There are two kinds:
    #  1. legacy namespace-package shims in several __init__ files (fs/, fs/opener/);
    #  2. real opener-plugin discovery in fs/opener/registry.py via entry points.
    # Drop the shims, and port the two discovery call sites to the stdlib
    # importlib.metadata API, whose EntryPoint exposes the same .name/.load().
    postPatch = (o.postPatch or "") + ''
      for f in $(grep -rl '__import__("pkg_resources").declare_namespace' fs); do
        substituteInPlace "$f" \
          --replace-quiet '__import__("pkg_resources").declare_namespace(__name__)' 'None'
      done
      substituteInPlace fs/opener/registry.py \
        --replace-fail 'import pkg_resources' 'from importlib.metadata import entry_points as _iter_eps' \
        --replace-fail 'pkg_resources.iter_entry_points("fs.opener", protocol)' 'iter(_iter_eps(group="fs.opener", name=protocol))' \
        --replace-fail 'pkg_resources.iter_entry_points("fs.opener")' '_iter_eps(group="fs.opener")'
    '';
    meta = (o.meta or { }) // { broken = false; };
  });
  pyfatfsFixed = python3Packages.pyfatfs.overridePythonAttrs (o: {
    disabled = false;
    doCheck = false;
    dontCheckRuntimeDeps = true;
    propagatedBuildInputs =
      (lib.filter (p: (p.pname or "") != "fs") (o.propagatedBuildInputs or [ ]))
      ++ [ fsFixed ];
    dependencies =
      (lib.filter (p: (p.pname or "") != "fs")
        (o.dependencies or o.propagatedBuildInputs or [ ]))
      ++ [ fsFixed ];
  });
in
unblob.overridePythonAttrs (o: {
  disabled = false;
  doCheck = false;
  dontCheckRuntimeDeps = true;
  propagatedBuildInputs = map
    (p: if (p.pname or "") == "pyfatfs" then pyfatfsFixed else p)
    (o.propagatedBuildInputs or [ ]);
  dependencies = map
    (p: if (p.pname or "") == "pyfatfs" then pyfatfsFixed else p)
    (o.dependencies or o.propagatedBuildInputs or [ ]);
})
