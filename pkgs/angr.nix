# angr: the binary-analysis platform. Two problems have to be fixed on this
# nixpkgs snapshot:
#
#   1. nixpkgs' angr 9.2.193 derivation misses the Rust build setup its
#      `rustylib` extension needs ("angr requires setuptools-rust to build"),
#      omits msgspec (imported at module load by angr.procedures.definitions),
#      and pins its sibling components to ==9.2.193 while the snapshot ships
#      9.2.154. Fixed below with setuptools-rust, the Rust toolchain, the
#      vendored cargo deps, msgspec, and a relaxed sibling-version pin.
#
#   2. The snapshot ships pycparser 3.00, a rewrite that removed the PLY-based C
#      parser angr's C-type engine drives (clex/cparser, the
#      `parameter_declaration` start symbol), so `import angr` fails outright.
#      angr is built here against a python whose pycparser is pinned back to the
#      last 2.x. The pin is scoped to this python via packageOverrides, so the
#      global python set - and the meson/python native stack (gtk4, wine,
#      pipewire, ...) that shares its binary cache - is untouched; only angr's
#      own closure (cffi and its dependents) rebuilds against pycparser 2.x.
{ lib, python3, fetchFromGitHub, rustPlatform, cargo, rustc }:

let
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
    };
  };
  pp = pythonAngr.pkgs;
in
pp.angr.overridePythonAttrs (o: {
  cargoDeps = rustPlatform.fetchCargoVendor {
    inherit (o) src;
    name = "angr-${o.version}-cargo-deps";
    hash = "sha256-HnvNJW7Q3bWr2VxtM+Ux0gyDC5P5QlHjZwooyOkGaow=";
  };

  nativeBuildInputs = (o.nativeBuildInputs or [ ]) ++ [
    pp.setuptools-rust
    rustPlatform.cargoSetupHook
    cargo
    rustc
  ];

  build-system = (o.build-system or [ ]) ++ [ pp.setuptools-rust ];

  dependencies = (o.dependencies or o.propagatedBuildInputs or [ ]) ++ [ pp.msgspec ];

  # Relax the exact sibling pins at the source so the built wheel's metadata
  # accepts the 9.2.154 pyvex/claripy/cle/... this nixpkgs actually ships.
  postPatch = (o.postPatch or "") + ''
    substituteInPlace pyproject.toml --replace-quiet "==9.2.193" ">=9.2.0"
  '';
  pythonRelaxDeps = true;
  dontCheckRuntimeDeps = true;
})
