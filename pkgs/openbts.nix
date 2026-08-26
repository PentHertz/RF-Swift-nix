# OpenBTS (2G GSM/GPRS BTS), PentHertz `resolute` fork. RF Swift ships this
# branch but its own Docker build leaves it FAILED under gcc-15 / libstdc++-15:
# the pervasive `using namespace std;` collides with libstdc++-15's new
# std::complex forward-declaration ("reference to 'complex' is ambiguous"). That
# forward-declaration only kicks in for C++17 and later, so building with
# `-std=gnu++14` (which OpenBTS's dynamic exception specifications need anyway)
# sidesteps it without a second toolchain - keeping one ABI so the gcc-15-built
# uhd/ortp/bctoolbox link cleanly.
{ lib
, stdenv
, fetchFromGitHub
, autoreconfHook
, pkg-config
, makeWrapper
, uhd
, boost
, libosip
, ortp
, bctoolbox
, cppzmq
, zeromq
, sqlite
, readline
, ncurses
, openssl
, libusb1
, liba53
}:

stdenv.mkDerivation {
  pname = "openbts";
  version = "5.1-resolute";

  src = fetchFromGitHub {
    owner = "PentHertz";
    repo = "OpenBTS";
    # resolute branch tip; a full SHA is required because fetchSubmodules uses
    # fetchgit, which would otherwise resolve a bare name as a tag.
    rev = "c68c49b210b6251e0cc5200edada9db51b080371";
    fetchSubmodules = true; # CommonLibs + NodeManager are submodules
    hash = "sha256-lcWXO0/aELcpyvsC22l29IPUtH1YEznztG+FWlhs9E8=";
  };

  nativeBuildInputs = [ autoreconfHook pkg-config makeWrapper ];
  buildInputs = [
    uhd boost libosip ortp bctoolbox cppzmq zeromq sqlite readline ncurses openssl libusb1 liba53
  ];

  postPatch = ''
    # Drop the dependency on Google's ancient libcoredumper. Its only real use is
    # one WriteCoreDump() call in a crash-signal handler (best-effort core dump);
    # stub it out. The remaining -lcoredumper references are in check-only test
    # programs and the apps link line.
    substituteInPlace apps/Makefile.am --replace-quiet " -lcoredumper" ""
    substituteInPlace CommonLibs/Makefile.am --replace-quiet " -lcoredumper" ""
    substituteInPlace CommonLibs/UnixSignal.cpp \
      --replace-quiet '#include <google/coredumper.h>' "" \
      --replace-quiet 'WriteCoreDump(buf);' '/* WriteCoreDump(buf); (libcoredumper removed) */'

    # configure.ac hard-probes /usr/include for zmq/a53 headers, which live in
    # the Nix store here. Skip those filesystem tests; the AC_CHECK_LIB /
    # AC_LINK_IFELSE checks right after them still validate the libraries
    # against the compiler (which sees the store include paths via NIX_CFLAGS).
    substituteInPlace configure.ac \
      --replace-quiet 'if test ! -r "/usr/include/zmq.h" -a ! -r "/usr/local/include/zmq.h"; then' 'if false; then' \
      --replace-quiet 'if test ! -r "/usr/include/zmq.hpp" -a ! -r "/usr/local/include/zmq.hpp"; then' 'if false; then' \
      --replace-quiet 'if test ! -r "/usr/include/a53.h" -a ! -r "/usr/local/include/a53.h"; then' 'if false; then'

    # apps/ and Transceiver52M have hand-written install rules that install to
    # absolute paths ($(DESTDIR)/OpenBTS, $(DESTDIR)/etc/...), which fail against
    # the read-only root. Redirect them under the Nix prefix ($out) instead.
    substituteInPlace apps/Makefile.am --replace-quiet '$(DESTDIR)/' '$(prefix)/'
    substituteInPlace Transceiver52M/Makefile.am --replace-quiet '$(DESTDIR)/' '$(prefix)/'

    # The UHD transceiver is built but marked noinst (not installed); promote it
    # to bin_PROGRAMS so libtool installs it into $out/bin with correct RPATH.
    substituteInPlace Transceiver52M/Makefile.am --replace-quiet 'noinst_PROGRAMS' 'bin_PROGRAMS'
  '';

  configureFlags = [ "--with-uhd" ];

  # OpenBTS is C++03/11-era: it uses dynamic exception specifications (throw(...))
  # that are hard errors under C++17 (gcc's default), and generally needs the
  # permissive legacy behaviour. Pin an old standard and quiet the legacy noise.
  env.NIX_CFLAGS_COMPILE = toString [
    "-std=gnu++17"          # UHD 4.10 headers need C++17 (std::optional); OpenBTS has no dynamic exception specs
    "-msse4.1"              # the Transceiver52M SIMD convert/convolve code uses SSE4.1 intrinsics
    "-fpermissive"
    "-fcommon"
    "-Wno-error"
    "-Wno-narrowing"
    "-Wno-deprecated"
    "-Wno-incompatible-pointer-types"
  ];

  enableParallelBuilding = true;

  # Redirect the config database to a writable per-user location and seed it
  # from the shipped example SQL on first run (the store is read-only, and the
  # default path is /etc/OpenBTS/OpenBTS.db).
  postInstall = ''
    # apps/ installs the binaries under $out/OpenBTS; put them on PATH. The
    # transceiver may land elsewhere, so locate it too.
    mkdir -p $out/bin
    for b in OpenBTSCLI OpenBTSDo; do
      [ -e "$out/OpenBTS/$b" ] && ln -sf "$out/OpenBTS/$b" "$out/bin/$b"
    done

    # The UHD transceiver is built noinst (not installed); its internal library
    # is a static convenience lib, so the built ELF is self-contained apart from
    # the external shared deps (which fixupPhase keeps RPATH'd). Install it.
    for cand in Transceiver52M/.libs/transceiver Transceiver52M/transceiver; do
      if [ -f "$cand" ] && head -c4 "$cand" | grep -q ELF; then
        install -Dm755 "$cand" "$out/bin/transceiver"; break
      fi
    done

    # Wrap the server so its config database lives in a writable per-user path,
    # seeded from the shipped example SQL on first run (the default is the
    # read-only /etc/OpenBTS/OpenBTS.db).
    if [ -e "$out/OpenBTS/OpenBTS" ]; then
      makeWrapper "$out/OpenBTS/OpenBTS" "$out/bin/OpenBTS" \
        --run 'export OpenBTSConfigFile="''${OpenBTSConfigFile:-$HOME/.config/OpenBTS/OpenBTS.db}"' \
        --run 'if [ ! -f "$OpenBTSConfigFile" ] && [ -f '"$out"'/etc/OpenBTS/OpenBTS.example.sql ]; then mkdir -p "$(dirname "$OpenBTSConfigFile")"; ${sqlite}/bin/sqlite3 -init '"$out"'/etc/OpenBTS/OpenBTS.example.sql "$OpenBTSConfigFile" ".quit" 2>/dev/null || true; fi'
    fi
  '';

  meta = {
    description = "OpenBTS: 2G GSM/GPRS base station (PentHertz resolute fork, UHD transceiver)";
    homepage = "https://github.com/PentHertz/OpenBTS";
    license = lib.licenses.agpl3Plus;
    platforms = [ "x86_64-linux" ];
  };
}
