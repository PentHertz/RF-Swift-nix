# Wifiphisher: rogue-AP framework for red-team WiFi phishing / association
# attacks. Drives roguehostapd (our openssl_1_1-linked build).
{ lib, python3Packages, fetchFromGitHub, roguehostapd, pkg-config, libnl
, openssl_1_1, dnsmasq }:

python3Packages.buildPythonApplication {
  pname = "wifiphisher";
  version = "1.4-unstable";
  format = "setuptools";

  src = fetchFromGitHub {
    owner = "wifiphisher";
    repo = "wifiphisher";
    rev = "master";
    hash = "sha256-RIvyiVwcfJgOAQs9+IMnLxEcE6tMl/3RzJDkkqDvFXI=";
  };

  postPatch = ''
    substituteInPlace setup.py \
      --replace-fail /usr/sbin/dnsmasq ${dnsmasq}/bin/dnsmasq \
      --replace-fail "shutil.rmtree('tmp')" "shutil.rmtree('tmp', ignore_errors=True)"
  '';

  # setup.py re-runs roguehostapd's netlink/openssl compile checks, so it needs
  # libnl (its headers live under include/libnl3) and openssl_1_1 at build time.
  nativeBuildInputs = [ pkg-config ];
  buildInputs = [ libnl openssl_1_1 ];
  env.NIX_CFLAGS_COMPILE = "-I${libnl.dev}/include/libnl3 -Wno-error";

  propagatedBuildInputs = (with python3Packages; [ pbkdf2 scapy tornado pyric ])
    ++ [ roguehostapd dnsmasq ];

  pythonRelaxDeps = true;
  dontCheckRuntimeDeps = true;
  doCheck = false;
  pythonImportsCheck = [ "wifiphisher" ];

  meta = {
    description = "Rogue Access Point framework for WiFi phishing / MITM";
    homepage = "https://github.com/wifiphisher/wifiphisher";
    license = lib.licenses.gpl3Only;
    platforms = [ "x86_64-linux" ];
    mainProgram = "wifiphisher";
  };
}
