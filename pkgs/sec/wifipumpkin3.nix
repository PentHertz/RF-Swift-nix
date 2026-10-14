{ lib, python3Packages, fetchFromGitHub }:
let
  pick = names: lib.filter (x: x != null) (map (n: python3Packages.${n} or null) names);
  # Pure-Python DHCP helpers wifipumpkin3 imports at startup (its DHCP server
  # and lease reader); neither is in nixpkgs.
  dhcplib = python3Packages.buildPythonPackage rec {
    pname = "dhcplib"; version = "0.1.1"; pyproject = true;
    src = python3Packages.fetchPypi { inherit pname version; hash = "sha256-033bYqDuNxDzpHYDRJA4rbUjKqooFYaRmExS60sGXG8="; };
    build-system = [ python3Packages.setuptools ];
    doCheck = false;
    pythonImportsCheck = [ "dhcplib" ];
    meta.license = lib.licenses.gpl3Only;
  };
  isc-dhcp-leases = python3Packages.buildPythonPackage rec {
    pname = "isc_dhcp_leases"; version = "0.10.0"; pyproject = true;
    src = python3Packages.fetchPypi { inherit pname version; hash = "sha256-oCyDwNm5EqjcSPOBh+a+x6TbyZuXh6VnMlrV8OyhzpA="; };
    build-system = [ python3Packages.setuptools ];
    dependencies = [ python3Packages.six ];
    doCheck = false;
    pythonImportsCheck = [ "isc_dhcp_leases" ];
    meta.license = lib.licenses.mit;
  };
in python3Packages.buildPythonApplication {
  pname = "wifipumpkin3"; version = "unstable"; pyproject = true;
  src = fetchFromGitHub { owner = "P0cL4bs"; repo = "wifipumpkin3"; rev = "344a47588f622730bc38b498b915e584cef4a19b"; hash = "sha256-WTEgX/L+qJu+LOQlwIOse2c8CRyQBam6YnLZOxVYhPE="; };
  build-system = pick [ "setuptools" ];
  # requirements.txt; dontCheckRuntimeDeps below hid the ones missing here.
  dependencies = pick [
    "pyqt5" "tornado" "netfilterqueue" "scapy" "requests" "pyroute2" "netaddr" "psutil"
    "netifaces" "tabulate" "urwid" "termcolor" "twisted" "pyopenssl" "dnslib" "loguru"
    "dnspython" "flask" "beautifulsoup4" "pyjwt" "flask-restful" "aiofiles" "ping3"
    "service-identity"
  ] ++ [ dhcplib isc-dhcp-leases ];
  # distutils is gone from Python >= 3.12. Its copy_tree is only used for plain
  # two-argument directory copies (shutil.copytree with dirs_exist_ok), and the
  # distutils.log import in terminal.py is unused.
  postPatch = ''
    for f in wifipumpkin3/core/config/setup.py wifipumpkin3/modules/misc/custom_captiveflask.py \
        wifipumpkin3/modules/misc/extra_captiveflask.py; do
      substituteInPlace $f --replace-fail "from distutils.dir_util import copy_tree" \
        "from functools import partial; from shutil import copytree; copy_tree = partial(copytree, dirs_exist_ok=True)"
    done
    substituteInPlace wifipumpkin3/core/common/terminal.py --replace-fail "from distutils.log import error" ""
  '';
  # Upstream setup.py creates ~/.config/wifipumpkin3 while querying build
  # requirements. Keep that unavoidable setup-time side effect in the sandbox.
  preBuild = ''
    export HOME="$TMPDIR"
  '';
  # setup.py installs its data_files (default config, templates, scripts) under
  # <prefix>/wifipumpkin3/data, but the code reads them from the package dir
  # (wifipumpkin3.__path__/data, which already holds exceptions/): merge them
  # there. Otherwise first run creates an empty ~/.config/wifipumpkin3 and every
  # later start fails on the missing settings.
  postInstall = ''
    cp -r $out/wifipumpkin3/data/. $out/${python3Packages.python.sitePackages}/wifipumpkin3/data/
    rm -r $out/wifipumpkin3
  '';
  pythonRelaxDeps = true; dontCheckRuntimeDeps = true; doCheck = false;
  meta = { description = "Rogue AP framework for red-team / MITM"; homepage = "https://github.com/P0cL4bs/wifipumpkin3"; license = lib.licenses.asl20; mainProgram = "wifipumpkin3"; };
}
