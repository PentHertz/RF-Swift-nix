# Mirage (RCayre): a BLE / Bluetooth / wireless attack framework.
#
# Mirage requires Python 3.10, so this is called with a python310 package set
# (see pkgs/default.nix). Built from source; firmware blobs the Docker image
# also downloads are runtime data and are not bundled here.
{ lib
, buildPythonApplication
, fetchFromGitHub
, setuptools
, scapy
, pyusb
, pyserial
, pycryptodomex
, psutil
, matplotlib
, terminaltables
, keyboard ? null
}:

buildPythonApplication {
  pname = "mirage";
  version = "unstable";
  pyproject = true;

  src = fetchFromGitHub {
    owner = "RCayre";
    repo = "mirage";
    rev = "master";
    hash = "sha256-IY6Y2djLFtGb8MGI7u8IHC3vnEF3s5xh5bdFU7Xcmc4=";
  };

  build-system = [ setuptools ];

  # Mirage pins scapy==2.5.0; relax so the py310 set's scapy is accepted.
  pythonRelaxDeps = true;

  dependencies = [ scapy pyusb pyserial pycryptodomex psutil matplotlib terminaltables ]
    ++ lib.optional (keyboard != null) keyboard;

  dontCheckRuntimeDeps = true;
  doCheck = false;

  meta = {
    description = "Mirage: BLE / Bluetooth / wireless attack framework";
    homepage = "https://github.com/RCayre/mirage";
    license = lib.licenses.mit;
    mainProgram = "mirage";
  };
}
