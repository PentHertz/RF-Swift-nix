# dragondrain-and-time: WPA3 SAE denial-of-service (dragondrain) and timing
# side-channel (dragontime) tools (vanhoefm). They live in an aircrack-ng source
# fork; we build ONLY the two dragon* targets (not the whole suite) so there is no
# collision with the aircrack-ng package.
{ lib, stdenv, fetchFromGitHub, autoreconfHook, pkg-config, libtool
, libnl, libpcap, openssl, zlib, sqlite, pcre2, libgcrypt, hwloc }:

stdenv.mkDerivation {
  pname = "dragondrain-and-time";
  version = "unstable";

  src = fetchFromGitHub {
    owner = "vanhoefm";
    repo = "dragondrain-and-time";
    rev = "82616a731032b0abca69acebfeda4574960bd5f4";
    hash = "sha256-2ZIQNaZa/B+sCawc++FR4s49kFhr4jUmH+9icWcFWmE=";
  };

  nativeBuildInputs = [ autoreconfHook pkg-config libtool ];
  buildInputs = [ libnl libpcap openssl zlib sqlite pcre2 libgcrypt hwloc ];
  # -fcommon: this old aircrack fork has tentative definitions (e.g. __packed)
  # that gcc-10+'s default -fno-common turns into multiple-definition link errors.
  env.NIX_CFLAGS_COMPILE = "-fcommon -Wno-error -Wno-incompatible-pointer-types -Wno-implicit-function-declaration -Wno-int-conversion";

  # Build the fork, then install ONLY the two dragon* binaries so nothing collides
  # with the aircrack-ng package.
  enableParallelBuilding = true;

  installPhase = ''
    runHook preInstall
    mkdir -p $out/bin
    find . -name dragondrain -type f -perm -u+x -exec install -Dm755 {} $out/bin/dragondrain \;
    find . -name dragontime  -type f -perm -u+x -exec install -Dm755 {} $out/bin/dragontime  \;
    runHook postInstall
  '';

  meta = {
    description = "WPA3 SAE DoS (dragondrain) and timing side-channel (dragontime) tools";
    homepage = "https://github.com/vanhoefm/dragondrain-and-time";
    license = lib.licenses.gpl2Plus;
    platforms = [ "x86_64-linux" ];
  };
}
