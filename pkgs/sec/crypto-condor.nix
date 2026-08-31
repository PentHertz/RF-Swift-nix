# crypto-condor (PyPI): a library + CLI for testing implementations of
# cryptographic primitives. Matches RF-Swift-images' crypto_condor install.
{ lib, python3Packages, fetchPypi }:

python3Packages.buildPythonApplication rec {
  pname = "crypto-condor";
  version = "2025.9.8";
  pyproject = true;

  src = fetchPypi {
    pname = "crypto_condor";
    inherit version;
    hash = "sha256-B+CTJpDXOGgVeUHSBKxWKzHGQcAtdgQUW1w+NVq4XlU=";
  };

  # Upstream builds with poetry-core (build-backend = poetry.core.masonry.api),
  # not setuptools; declaring setuptools makes the PEP 517 build fail with
  # "Backend 'poetry.core.masonry.api' is not available."
  build-system = with python3Packages; [ poetry-core ];
  dependencies = with python3Packages; [
    attrs cffi cryptography lief protobuf pycryptodome strenum typer
  ];
  # Upstream pins tight upper bounds (protobuf<6, cryptography<44, typer<0.18)
  # that this nixpkgs pin exceeds; relax and skip the runtime-deps check.
  pythonRelaxDeps = true;
  dontCheckRuntimeDeps = true;

  meta = {
    description = "Compliance-testing tool for implementations of cryptographic primitives";
    homepage = "https://pypi.org/project/crypto-condor/";
    license = lib.licenses.gpl3Plus;
    platforms = lib.platforms.unix;
    mainProgram = "crypto-condor";
  };
}
