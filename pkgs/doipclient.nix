# doipclient (jacobschaer/python-doipclient): Diagnostic over IP (ISO 13400-2)
# client library. Matches the doipclient part of RF-Swift-images'
# can_python_tools_soft_install (pip3 install udsoncan doipclient). Library only,
# so it is called through python3Packages.callPackage. udsoncan is not a hard
# dependency upstream (only doipclient.connectors imports it): exposed as the
# "udsoncan" extra and used by the tests.
{ lib, buildPythonPackage, fetchFromGitHub, setuptools, wheel, udsoncan
, pytestCheckHook, pytest-mock }:

buildPythonPackage {
  pname = "doipclient";
  version = "1.2.2";
  pyproject = true;

  src = fetchFromGitHub {
    owner = "jacobschaer";
    repo = "python-doipclient";
    rev = "9887b80c2cc61686a6fdb5314724e026bb4e9a25"; # v1.2.2
    hash = "sha256-gDz6+8Z5dkiErr8Zz3jty085FTP7Qb/0PzuF5mGCfsI=";
  };

  build-system = [ setuptools wheel ];

  optional-dependencies.udsoncan = [ udsoncan ];

  # Tests run against a mocked socket, no network needed.
  nativeCheckInputs = [ pytestCheckHook pytest-mock udsoncan ];
  pythonImportsCheck = [ "doipclient" ];

  meta = {
    description = "Diagnostic over IP (DoIP, ISO 13400-2) client library";
    homepage = "https://github.com/jacobschaer/python-doipclient";
    license = lib.licenses.mit;
    platforms = lib.platforms.unix;
  };
}
