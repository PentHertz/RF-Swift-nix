{ lib
, stdenv
, fetchFromGitHub
, buildGoModule
, rustPlatform
, python3Packages
, cmake
, pkg-config
, nix-update-script
}:

# Declarative builder for uncomplicated GitHub-hosted tools. Packages with
# patches, unusual dependency graphs, or vendor binaries should keep a normal
# derivation. See templates/packages and docs/adding-packages.md.
spec:
let
  common = {
    inherit (spec) pname version;
    src = fetchFromGitHub {
      inherit (spec.source) owner repo rev hash;
      fetchSubmodules = spec.source.fetchSubmodules or false;
    };
    meta = {
      description = spec.description;
      homepage = spec.homepage or "https://github.com/${spec.source.owner}/${spec.source.repo}";
      license = lib.licenses.${spec.license};
      mainProgram = spec.mainProgram or spec.pname;
      platforms = spec.platforms or lib.platforms.unix;
    };
    passthru = {
      updateScript = nix-update-script { };
      updateBranch = spec.source.updateBranch or null;
      sourceOwner = spec.source.owner;
      sourceRepo = spec.source.repo;
    };
  };
in
if spec.build == "go" then
  buildGoModule
    (common // {
      vendorHash = spec.vendorHash;
      subPackages = spec.subPackages or [ ];
      ldflags = spec.ldflags or [ ];
    })
else if spec.build == "rust" then
  rustPlatform.buildRustPackage
    (common // {
      cargoHash = spec.cargoHash;
    })
else if spec.build == "python" then
  python3Packages.buildPythonApplication
    (common // {
      pyproject = spec.pyproject or true;
      build-system = spec.buildSystem or [ python3Packages.setuptools ];
      dependencies = spec.dependencies or [ ];
      pythonImportsCheck = spec.pythonImportsCheck or [ ];
    })
else if spec.build == "cmake" then
  stdenv.mkDerivation
    (common // {
      nativeBuildInputs = [ cmake pkg-config ] ++ (spec.nativeBuildInputs or [ ]);
      buildInputs = spec.buildInputs or [ ];
      cmakeFlags = spec.cmakeFlags or [ ];
    })
else
  throw "mkGitHubTool: unsupported build type '${spec.build}'"
