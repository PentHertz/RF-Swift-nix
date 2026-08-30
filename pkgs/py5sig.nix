# py5sig: builds 5G core signalling (SBI/HTTP2) messages and fuzzes SBI
# interfaces (ANSSI). The telecom image pipx-installs it from git; here it is
# a normal pyproject application. Upstream pins exact dependency versions, so
# they are relaxed to whatever the pinned nixpkgs carries.
{ lib, python3Packages, fetchFromGitHub }:

python3Packages.buildPythonApplication {
  pname = "py5sig";
  version = "0.1.0";
  pyproject = true;

  src = fetchFromGitHub {
    owner = "ANSSI-FR";
    repo = "py5sig";
    rev = "cc4e4847852c0269814e923f488b0d4dde57be84";
    hash = "sha256-uTLqXjCZOYgqkRgfSKrZBFFX5iiWLsxXel2AJlO5Pqo=";
  };

  build-system = [ python3Packages.setuptools ];
  pythonRelaxDeps = true;
  dependencies = with python3Packages; [
    anyio certifi h11 httpcore httpx h2 idna sniffio
    rich-click pyjwt validators prance openapi-spec-validator
  ];

  doCheck = false;
  pythonImportsCheck = [ "py5sig" ];

  meta = {
    description = "5G SBI signalling message builder and fuzzer (ANSSI)";
    homepage = "https://github.com/ANSSI-FR/py5sig";
    license = lib.licenses.bsd2;
    mainProgram = "py5sig";
    platforms = lib.platforms.unix;
  };
}
