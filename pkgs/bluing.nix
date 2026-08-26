# bluing (fO-000): a Bluetooth intelligence-gathering tool.
#
# Requires Python 3.10, so this is called with a python310 package set (see
# pkgs/default.nix). RF Swift installs six fO-000 helper wheels (--no-deps) plus
# bluing from git; we reproduce that here. The wheels are pure-Python
# (py3-none-any), so they just need fetching.
#
# Each `lib.fakeHash` must be pinned individually (one per source); update.sh
# cannot pin a multi-source file. Build with `nix build .#pkg-bluing`, read the
# reported hash, paste it into the matching source, repeat.
{ lib
, buildPythonApplication
, buildPythonPackage
, fetchurl
, fetchFromGitHub
, setuptools
, stdeb
, pyserial
, docopt ? null
, halo ? null
, configobj ? null
, ntplib ? null
, pkginfo ? null
, dbus-python ? null
, pygobject3 ? null
, bluepy ? null
}:

let
  optl = xs: lib.filter (x: x != null) xs;

  # A pure-Python (py3-none-any) wheel installed with no dependency checks,
  # mirroring RF Swift's `pip install --no-deps <wheel>`.
  wheelPkg = pname: version: url: hash: buildPythonPackage {
    inherit pname version;
    format = "wheel";
    src = fetchurl { inherit url hash; };
    doCheck = false;
    dontCheckRuntimeDeps = true;
    pythonImportsCheck = [ ];
  };

  xpycommon = wheelPkg "xpycommon" "0.0.25"
    "https://files.pythonhosted.org/packages/80/47/a9e2dfc8acb8a134fed62b0ef28282229728c99f63ae957b4bad20b907a7/xpycommon-0.0.25-py3-none-any.whl"
    "sha256-tFPOqrBA1OgjO+h/2aOUbZmgrcFAURNCp6PK7ki3hDQ=";
  bthci = wheelPkg "bthci" "0.0.44"
    "https://files.pythonhosted.org/packages/c5/6b/ecc4a62772fd2af49b0c5245b0beef9fe7b01f1ea642c2a69c859783ace1/bthci-0.0.44-py3-none-any.whl"
    "sha256-WNovJOA+aoWzW0cFzr6u54e5yvy2kWkwaMCG7LRnMF8=";
  btl2cap = wheelPkg "btl2cap" "0.0.11"
    "https://files.pythonhosted.org/packages/e0/b8/4339dfd7b98360510f0efb1d8f1b475a4e289f1f4a3e7ffd50ddeb0bd030/btl2cap-0.0.11-py3-none-any.whl"
    "sha256-o+9Un3A2TOoSweqGtSY8MCw1fXkmJPoW9UrYI3Cx1RY=";
  btatt = wheelPkg "btatt" "0.0.19"
    "https://files.pythonhosted.org/packages/8d/38/77e3f4f3eae7cb5950d0993a5ead81993f86e45b97691177df44b4586056/btatt-0.0.19-py3-none-any.whl"
    "sha256-RN5GDCRQJ4Xq9lnGdkonOHjJ71VWe9HqNELSQW3tn7o=";
  btgatt = wheelPkg "btgatt" "0.0.22"
    "https://files.pythonhosted.org/packages/bd/19/a8f9bd80e40654bf5f170a60cc98e00a64bfc3f8d3fc40804a23a50b7651/btgatt-0.0.22-py3-none-any.whl"
    "sha256-zF5oJYHk1bmcGYCVdjTcGzXuxs3qec+GJeV1Fu5E7w4=";
  btsm = wheelPkg "btsm" "0.0.16"
    "https://files.pythonhosted.org/packages/3a/3d/2467113e463f903cf9fe12f621744c1fab634d9f95e654fa3ad05c793281/btsm-0.0.16-py3-none-any.whl"
    "sha256-j4ZayrQGzPClgcNDSSQUFM2+sZLFQ885+xK3imNx5jw=";
in
buildPythonApplication {
  pname = "bluing";
  version = "unstable";
  pyproject = true;

  src = fetchFromGitHub {
    owner = "fO-000";
    repo = "bluing";
    rev = "master";
    hash = "sha256-Qx2Rmbmml/W4qDNrlkXYbI9JDv8Ga8eRrVtg1Bu8DYo=";
  };

  # bluing's setup declares stdeb as a build requirement.
  build-system = [ setuptools stdeb ];
  pythonRelaxDeps = true;

  dependencies = [ xpycommon bthci btl2cap btatt btgatt btsm pyserial ]
    ++ optl [ docopt halo configobj ntplib pkginfo dbus-python pygobject3 bluepy ];

  dontCheckRuntimeDeps = true;
  doCheck = false;

  meta = {
    description = "bluing: Bluetooth intelligence gathering (fO-000)";
    homepage = "https://github.com/fO-000/bluing";
    license = lib.licenses.gpl3Plus;
    mainProgram = "bluing";
  };
}
