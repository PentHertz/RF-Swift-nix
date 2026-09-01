# roguehostapd: hostapd wrapper with KARMA/rogue-AP patches (wifiphisher). Its
# custom build compiles a bundled hostapd 2.6 into a shared library; that hostapd
# only speaks the OpenSSL 1.1 API, so we link the resurrected openssl_1_1. The two
# hardcoded /usr include paths are repointed at the Nix libnl3 / openssl dirs.
{ lib, python3Packages, fetchFromGitHub, pkg-config, openssl_1_1, libnl }:

python3Packages.buildPythonPackage {
  pname = "roguehostapd";
  version = "1.9.0";
  format = "setuptools";

  src = fetchFromGitHub {
    owner = "wifiphisher";
    repo = "roguehostapd";
    rev = "381b373b4b3394d916e8c7a19b10d6c3c491bd13";
    hash = "sha256-rPIiIi3leUyWOIYOt10PTY1HMpwcUcvYVVyGb/jZk4E=";
  };

  nativeBuildInputs = [ pkg-config ];
  buildInputs = [ openssl_1_1 libnl ];

  postPatch = ''
    # Python 3.14's fd-safe rmtree can observe the compiler's temporary tree
    # disappearing underneath it. Cleanup must not invalidate an otherwise
    # successful wheel build.
    substituteInPlace setup.py \
      --replace-fail "shutil.rmtree('tmp')" "shutil.rmtree('tmp', ignore_errors=True)"
    substituteInPlace roguehostapd/buildutil/build_files.py \
      --replace-fail "LIB_NL3_PATH = '/usr/include/libnl3'" "LIB_NL3_PATH = '${libnl.dev}/include/libnl3'" \
      --replace-fail "LIB_SSL_PATH = '/usr/include/openssl'" "LIB_SSL_PATH = '${openssl_1_1}/include'"
    # SafeConfigParser was removed from configparser in Python 3.12.
    substituteInPlace roguehostapd/config/hostapdconfig.py \
      --replace-fail "from configparser import SafeConfigParser" "from configparser import ConfigParser as SafeConfigParser"
  '';

  # hostapd 2.6 is old C: silence gcc-15's stricter errors.
  env.NIX_CFLAGS_COMPILE = "-Wno-error -Wno-implicit-function-declaration -Wno-int-conversion";
  dontCheckRuntimeDeps = true;
  doCheck = false;
  pythonImportsCheck = [ "roguehostapd" ];

  meta = {
    description = "hostapd wrapper with KARMA/rogue-AP support (wifiphisher backend)";
    homepage = "https://github.com/wifiphisher/roguehostapd";
    license = lib.licenses.gpl2Plus;
    platforms = [ "x86_64-linux" ];
  };
}
