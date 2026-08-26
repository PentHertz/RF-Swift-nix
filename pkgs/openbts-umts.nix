# OpenBTS-UMTS (3G UMTS/W-CDMA NodeB), PentHertz `resolute` fork. Like OpenBTS
# 2G, RF Swift's own build leaves this FAILED under gcc-15 / libstdc++-15. Same
# fix: single gcc-15 toolchain with -std=gnu++17 (which both dodges libstdc++'s
# std::complex forward-declaration and satisfies UHD 4.x's C++17 headers).
{ lib
, stdenv
, fetchFromGitHub
, autoreconfHook
, pkg-config
, makeWrapper
, asn1c
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
}:

stdenv.mkDerivation {
  pname = "openbts-umts";
  version = "resolute";

  src = fetchFromGitHub {
    owner = "PentHertz";
    repo = "OpenBTS-UMTS";
    rev = "e7baf152e40c670bcc3a9f12e7099417b8bb4f88"; # resolute tip (full SHA for submodules)
    fetchSubmodules = true; # NodeManager submodule
    hash = "sha256-eWtHmkAPp2wHNmSvvbmlEXao8lEsuxOZvL8rVQ/rP9c=";
  };

  # asn1c generates C from the UMTS ASN.1 specs at build time.
  nativeBuildInputs = [ autoreconfHook pkg-config makeWrapper asn1c ];
  buildInputs = [
    uhd boost libosip ortp bctoolbox cppzmq zeromq sqlite readline ncurses openssl libusb1
  ];

  postPatch = ''
    # configure.ac hard-probes /usr/include for the zmq headers (which live in
    # the Nix store); skip those tests. The AC_CHECK_LIB/AC_LINK_IFELSE checks
    # after them still validate zmq against the compiler.
    substituteInPlace configure.ac \
      --replace-quiet 'if test ! -r "/usr/include/zmq.h" -a ! -r "/usr/local/include/zmq.h"; then' 'if false; then' \
      --replace-quiet 'if test ! -r "/usr/include/zmq.hpp" -a ! -r "/usr/local/include/zmq.hpp"; then' 'if false; then'

    # apps/ and TransceiverUHD/ install to absolute paths ($(DESTDIR)/OpenBTS,
    # $(DESTDIR)/etc/...); redirect them under the Nix prefix ($out).
    substituteInPlace apps/Makefile.am --replace-quiet '$(DESTDIR)/' '$(prefix)/'
    substituteInPlace TransceiverUHD/Makefile.am --replace-quiet '$(DESTDIR)/' '$(prefix)/'

    # -march=native makes the binary non-portable and is redundant; the SIMD
    # convert/convolve code only needs SSE4.1.
    substituteInPlace TransceiverUHD/Makefile.am --replace-quiet '-march=native' '-msse4.1'

    # The ASN dir's hand-written makefile calls a bare `libtool`, which builds
    # libRRCASN both static and shared. The ~1000-object static `.a` is huge (it
    # blows the sandbox disk quota). Point both the compile (run from o/) and the
    # link (run from ASN/) at the project's own libtool, which ./configure wrote
    # with --disable-static -> PIC-only objects, no static archive at all.
    substituteInPlace ASN/makefile \
      --replace-quiet 'cd $O && libtool --mode=compile' 'cd $O && ../../libtool --mode=compile' \
      --replace-quiet 'libtool --mode=link gcc -g -O0 -o $(LIBTARGET)' '../libtool --mode=link gcc -g -O0 -o $(LIBTARGET)'

    # The config DB path is hard-coded to the read-only /etc/OpenBTS. Make it
    # honour an env var so a wrapper can point it at a writable per-user path.
    substituteInPlace apps/OpenBTS-UMTS.cpp \
      --replace-quiet '"/etc/OpenBTS/OpenBTS-UMTS.db"' \
        '(getenv("OpenBTSUMTSConfigFile")?:"/etc/OpenBTS/OpenBTS-UMTS.db")'
  '';

  # --disable-static: the RRC ASN.1 module is ~1000 objects; libtool's static
  # `ar` archive step for it is huge and trips the sandbox archiver. The shared
  # libraries are all the binaries need.
  configureFlags = [ "--with-uhd" "--disable-static" ];

  env.NIX_CFLAGS_COMPILE = toString [
    "-std=gnu++17"          # dodge libstdc++-15's std::complex forward-decl + satisfy UHD C++17 headers
    "-msse4.1"
    "-fpermissive"
    "-fcommon"
    "-Wno-error"
    "-Wno-narrowing"
    "-Wno-deprecated"
    "-Wno-incompatible-pointer-types"
  ];

  enableParallelBuilding = true;


  postInstall = ''
    mkdir -p $out/bin
    for b in OpenBTS-UMTS OpenBTS-UMTSCLI OpenBTS-UMTSDo transceiver; do
      [ -e "$out/OpenBTS/$b" ] && ln -sf "$out/OpenBTS/$b" "$out/bin/$b"
    done

    # Wrap the server so its config database lives in a writable per-user path,
    # seeded from the shipped example SQL on first run.
    if [ -e "$out/OpenBTS/OpenBTS-UMTS" ]; then
      rm -f "$out/bin/OpenBTS-UMTS"
      makeWrapper "$out/OpenBTS/OpenBTS-UMTS" "$out/bin/OpenBTS-UMTS" \
        --run 'export OpenBTSUMTSConfigFile="''${OpenBTSUMTSConfigFile:-$HOME/.config/OpenBTS/OpenBTS-UMTS.db}"' \
        --run 'if [ ! -f "$OpenBTSUMTSConfigFile" ] && [ -f '"$out"'/etc/OpenBTS/OpenBTS-UMTS.example.sql ]; then mkdir -p "$(dirname "$OpenBTSUMTSConfigFile")"; ${sqlite}/bin/sqlite3 -init '"$out"'/etc/OpenBTS/OpenBTS-UMTS.example.sql "$OpenBTSUMTSConfigFile" ".quit" 2>/dev/null || true; fi'
    fi
  '';

  meta = {
    description = "OpenBTS-UMTS: 3G UMTS/W-CDMA NodeB (PentHertz resolute fork, UHD)";
    homepage = "https://github.com/PentHertz/OpenBTS-UMTS";
    license = lib.licenses.agpl3Plus;
    platforms = [ "x86_64-linux" ];
  };
}
