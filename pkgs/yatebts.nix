# YateBTS: GSM/GPRS BTS running on top of the YATE telephony engine (PentHertz
# rc3 fork). Built against the nixpkgs `yate`.
{ lib, stdenv, fetchFromGitHub, autoreconfHook, pkg-config, yate, libusb1 }:

stdenv.mkDerivation {
  pname = "yatebts";
  version = "rc3-unstable";

  src = fetchFromGitHub {
    owner = "PentHertz";
    repo = "yatebts-rc3-nonoff";
    rev = "7eaece0c54a9635ad065e5728901488d6638556f";
    hash = "sha256-CWHUhMMSWWxJoF8XdVbwJ+vNz8YrCb2VpHcjfwjnag4=";
  };

  # The configure.ac lives in the yatebts/ subdirectory of the repo.
  sourceRoot = "source/yatebts";

  # yate on nativeBuildInputs puts yate-config on PATH so configure finds it.
  nativeBuildInputs = [ autoreconfHook pkg-config yate ];
  buildInputs = [ yate libusb1 ];

  # Install into $out instead of yate's read-only module dir.
  installFlags = [
    "moddir=${placeholder "out"}/lib/yate"
    "confdir=${placeholder "out"}/etc/yate"
    "docdir=${placeholder "out"}/share/doc/yatebts"
    "scrdir=${placeholder "out"}/share/yate/scripts"
    "shrdir=${placeholder "out"}/share/yate"
    "snddir=${placeholder "out"}/share/yate/sounds"
    "webdir=${placeholder "out"}/share/yate/web"
  ];
  env.NIX_CFLAGS_COMPILE = "-fcommon -Wno-error -Wno-incompatible-pointer-types -Wno-implicit-function-declaration -Wno-int-conversion";

  # nixpkgs' `yate-config --ldflags` (used at build time by the module link rule)
  # emits flags that are broken under the Nix toolchain: a `-Wl,--retain-symbols-file`
  # with no filename (ld then eats the next flag as its argument) and a raw
  # `--unresolved-symbols=...` that gcc forwards to ld as an input file. Shadow
  # yate-config with a wrapper that fixes its output.
  preConfigure = ''
    mkdir -p "$TMPDIR/yatewrap"
    cat > "$TMPDIR/yatewrap/yate-config" <<EOF
    #!/bin/sh
    ${yate}/bin/yate-config "\$@" | sed 's/-Wl,--retain-symbols-file//g'
    EOF
    sed -i 's/^    //' "$TMPDIR/yatewrap/yate-config"
    chmod +x "$TMPDIR/yatewrap/yate-config"
    export PATH="$TMPDIR/yatewrap:$PATH"
  '';

  meta = {
    description = "GSM/GPRS BTS for the YATE telephony engine (PentHertz rc3 fork)";
    homepage = "https://github.com/PentHertz/yatebts-rc3-nonoff";
    license = lib.licenses.gpl2Only;
    # Builds on aarch64 too (routinely compiled on Raspberry Pi).
    platforms = [ "x86_64-linux" "aarch64-linux" ];
  };
}
