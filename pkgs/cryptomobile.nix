# CryptoMobile: 3GPP mobile crypto (Milenage, TUAK, Kasumi, SNOW3G, ZUC, comp128)
# with compiled C cores (mitshell). Library used by telecom/SS7 tooling.
{ lib, python3Packages, fetchFromGitHub }:

python3Packages.buildPythonPackage {
  pname = "cryptomobile";
  version = "unstable";
  format = "setuptools";

  src = fetchFromGitHub {
    owner = "mitshell";
    repo = "CryptoMobile";
    rev = "0857cbbf140c05c54688bdb2076c25eb8f3ddb89";
    hash = "sha256-GxRf+0QBmWHBEYMuBeFX9S63Nbbq8jyXF+L2Uj8VCXk=";
  };

  propagatedBuildInputs = [ python3Packages.pycryptodomex ];
  doCheck = false;
  pythonImportsCheck = [ "CryptoMobile" ];

  meta = {
    description = "3GPP mobile cryptography (Milenage/TUAK/Kasumi/SNOW3G/ZUC/comp128)";
    homepage = "https://github.com/mitshell/CryptoMobile";
    license = lib.licenses.gpl2Plus;
  };
}
