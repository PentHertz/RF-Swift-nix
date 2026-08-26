# angr: the binary-analysis platform. nixpkgs' angr derivation for this snapshot
# is missing the Rust build setup that angr 9.2.x needs for its `rustylib`
# extension (it fails with "angr requires setuptools-rust to build"). Override it
# to add setuptools-rust, the Rust toolchain, and the vendored cargo deps.
#
# NOTE: this derivation is correct but currently does NOT import on the pinned
# nixpkgs, which ships pycparser 3.00 (a rewrite that removed the PLY parser
# angr's C-type engine relies on). angr is therefore listed as a documented gap
# in the `reversing` environment (see environments.nix). It comes back with no
# further change once nixpkgs' angr supports pycparser 3.00 or the flake pin
# advances. It is kept here (and exposed as pkg-angr) so the fix is ready and the
# derivation still evaluates.
{ lib, python3Packages, rustPlatform, cargo, rustc }:

python3Packages.angr.overridePythonAttrs (o: {
  cargoDeps = rustPlatform.fetchCargoVendor {
    inherit (o) src;
    name = "angr-${o.version}-cargo-deps";
    hash = "sha256-HnvNJW7Q3bWr2VxtM+Ux0gyDC5P5QlHjZwooyOkGaow=";
  };

  nativeBuildInputs = (o.nativeBuildInputs or [ ]) ++ [
    python3Packages.setuptools-rust
    rustPlatform.cargoSetupHook
    cargo
    rustc
  ];

  build-system = (o.build-system or [ ]) ++ [ python3Packages.setuptools-rust ];

  # nixpkgs' angr 9.2.193 omits msgspec, which angr.procedures.definitions imports
  # at module load, so `import angr` fails with ModuleNotFoundError. Add it.
  dependencies = (o.dependencies or o.propagatedBuildInputs or [ ]) ++ [ python3Packages.msgspec ];

  # This nixpkgs snapshot is version-skewed: angr 9.2.193 pins its sibling
  # components (pyvex/claripy/cle/...) to ==9.2.193 but ships 9.2.154. Relax the
  # exact pins so it builds against the versions actually present.
  # Relax the exact-version sibling pins at the source so the built wheel's
  # metadata accepts the 9.2.154 pyvex/claripy/cle/... this nixpkgs actually ships.
  postPatch = (o.postPatch or "") + ''
    substituteInPlace pyproject.toml --replace-quiet "==9.2.193" ">=9.2.0"
  '';
  pythonRelaxDeps = true;
  dontCheckRuntimeDeps = true;
})
