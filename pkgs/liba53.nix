# liba53: the A5/1, A5/3 and GEA GSM cipher library (PentHertz fork), a build
# dependency of OpenBTS. Plain Makefile that hardcodes /usr/{lib,include}; we
# build the shared object and install it into $out ourselves.
{ lib, stdenv, fetchFromGitHub }:

stdenv.mkDerivation {
  pname = "liba53";
  version = "unstable";

  src = fetchFromGitHub {
    owner = "PentHertz";
    repo = "liba53";
    rev = "27354560dc7b554e03d40a520d41290e731193b6";
    hash = "sha256-4ahnJ4qv/QFtND69BckanIKHURkQqmfr43m+O+PlJZw=";
  };

  # Default make target builds liba53.so.1.0 (+ the .so/.so.1 symlinks).
  installPhase = ''
    runHook preInstall
    mkdir -p $out/lib $out/include
    cp -P liba53.so* $out/lib/
    cp a53.h $out/include/
    runHook postInstall
  '';

  meta = {
    description = "A5/1, A5/3 and GEA GSM cipher library (OpenBTS dependency)";
    homepage = "https://github.com/PentHertz/liba53";
    license = lib.licenses.gpl2Plus;
    # Plain C, no arch-specific code: x86_64 and aarch64 (OpenBTS on arm64).
    platforms = [ "x86_64-linux" "aarch64-linux" ];
  };
}
