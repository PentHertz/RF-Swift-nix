# angr: the binary-analysis platform. Two problems have to be fixed on this
# nixpkgs snapshot:
#
#   1. The snapshot is a mid-staging angr suite whose component versions do not
#      line up: nixpkgs ships angr and claripy at 9.2.193 but cle, pyvex and
#      archinfo at 9.2.154 (and ailment at 9.2.158). The angr suite is released
#      and only tested in lockstep, and 9.2.193's code calls symbols the 9.2.154
#      siblings do not have (e.g. `PEStubs` from cle, an ImportError at
#      angr.analyses.cfg load time), so the versions must be made consistent.
#
#      We align *down* to 9.2.154 rather than up to 9.2.193, because down is by
#      far the smaller, safer change on this snapshot:
#        - angr 9.2.154 is a plain setuptools build. The Rust `rustylib`
#          extension (which nixpkgs' 9.2.193 derivation famously fails to build,
#          "angr requires setuptools-rust to build") was added after 9.2.154, so
#          there is no Rust toolchain, cargo-vendor or setuptools-rust to wire
#          up, and no ~15-minute Rust compile in the cache build.
#        - angr 9.2.154 does not import msgspec or lmdb at load time (9.2.193
#          does, and nixpkgs omits both), so those gaps disappear too.
#        - cle/pyvex/archinfo already *are* 9.2.154 in nixpkgs and are built for
#          it, so they need no override. Only angr, claripy and ailment are
#          downgraded to 9.2.154 to join them.
#      Aligning up to 9.2.193 would instead require repackaging pyvex (9.2.193
#      moved from a setuptools/Makefile build to scikit-build-core/CMake) and
#      hand-packaging cle 9.2.193's new deps, one of which (pyxdia) is not in
#      nixpkgs at all.
#
#   2. The snapshot ships pycparser 3.00, a rewrite that removed the PLY-based C
#      parser angr's C-type engine drives (clex/cparser, the
#      `parameter_declaration` start symbol), so `import angr` fails outright.
#      angr is built here against a python whose pycparser is pinned back to the
#      last 2.x. The pin is scoped to this python via packageOverrides, so the
#      global python set - and the meson/python native stack (gtk4, wine,
#      pipewire, ...) that shares its binary cache - is untouched; only angr's
#      own closure (cffi and its dependents) rebuilds against pycparser 2.x.
{ lib, python3, fetchFromGitHub }:

let
  # The consistent angr-suite version this derivation aligns the whole set to
  # (see note 1). cle, pyvex and archinfo already ship at this version in
  # nixpkgs; angr, claripy and ailment are downgraded to it below.
  angrVersion = "9.2.154";

  # Downgrade a nixpkgs angr-suite package (owner "angr", tagged v${version}) to
  # angrVersion, skipping its test suite. The wheel-metadata sibling pins are
  # relaxed on the consumers (angr/claripy) via pythonRelaxDeps, so an exact
  # match on every sibling is not required here.
  toSuiteVersion = pkg: repo: hash: pkg.overridePythonAttrs (_: {
    version = angrVersion;
    src = fetchFromGitHub {
      owner = "angr";
      inherit repo;
      rev = "v${angrVersion}";
      inherit hash;
    };
    doCheck = false;
    dontCheckRuntimeDeps = true;
  });

  pythonAngr = python3.override {
    packageOverrides = pySelf: pySuper: {
      pycparser = pySuper.pycparser.overridePythonAttrs (old: {
        version = "2.22";
        src = fetchFromGitHub {
          owner = "eliben";
          repo = "pycparser";
          rev = "release_v2.22";
          hash = "sha256-RY0xQ4Mj8IfYAcypZQx4lDBmcgzYqtM4ARm9NSccBgA=";
        };
      });
      claripy = toSuiteVersion pySuper.claripy "claripy"
        "sha256-90JX+VDWK/yKhuX6D8hbLxjIOS8vGKrN1PKR8iWjt2o=";
      ailment = toSuiteVersion pySuper.ailment "ailment"
        "sha256-JjS+jYWrbErkb6uM0DtB5h2ht6ZMmiYOQL/Emm6wC5U=";
    };
  };
  pp = pythonAngr.pkgs;
in
pp.angr.overridePythonAttrs (o: {
  version = angrVersion;
  src = fetchFromGitHub {
    owner = "angr";
    repo = "angr";
    rev = "v${angrVersion}";
    hash = "sha256-aOgZXHk6GTWZAEraZQahEXUYs8LWAWv1n9GfX+2XTPU=";
  };

  # angr 9.2.154 pins its siblings ==9.2.154 (all satisfied by the set above)
  # and unicorn==2.0.1.post1 / pypcode~=3.0, which the snapshot ships at newer
  # patch levels. Relax the wheel-metadata pins and skip the runtime-deps check
  # so those newer-but-compatible pins do not fail the build.
  pythonRelaxDeps = true;
  dontCheckRuntimeDeps = true;
  doCheck = false;
})
