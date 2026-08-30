# Open5GS training variants: FlUxIuS's patched branches of Open5GS 2.7.5 that
# the telecom_4Gto5G_extended image builds next to stock Open5GS —
#   nohttp2: SBI over HTTP/1.1 only (no HTTP/2), for interception/fuzzing labs;
#   0caps:   accepts UEs advertising zero security capabilities.
# Same recipe as nixpkgs' open5gs (whose vendored subproject sources we reuse),
# different source. Every installed program is prefixed with the variant name
# (Open5GS_nohttp2-amfd, ...) so a variant coexists with stock open5gs on one
# PATH, and the all-in-one 5G core runner (tests/app/5gc — what the image links
# as Open5Gs_*_deployall) is installed as the variant's main command.
{ lib, stdenv, fetchFromGitHub, open5gs, variant, rev, hash, description }:

let
  # 2.7.x still declares a usrsctp subproject wrap; provide its source too so
  # meson never reaches for the network, whichever subprojects this branch pulls.
  usrsctp = fetchFromGitHub {
    owner = "sctplab";
    repo = "usrsctp";
    rev = "07f871bda23943c43c9e74cc54f25130459de830"; # 0.9.5.0
    hash = "sha256-Sengtkg4UoA03cPy5+dRSr5qKIttWHEKn48udOP8zYI=";
  };
  name = "Open5GS_${variant}";
in
open5gs.overrideAttrs (old: {
  pname = "open5gs_${variant}";
  version = "2.7.5-${variant}";
  src = fetchFromGitHub {
    owner = "FlUxIuS";
    repo = "open5gs";
    inherit rev hash;
  };

  preConfigure = (old.preConfigure or "") + ''
    cp -R --no-preserve=mode,ownership ${usrsctp} subprojects/usrsctp
  '';

  postInstall = (old.postInstall or "") + ''
    for f in "$out"/bin/open5gs-*; do
      mv "$f" "$out/bin/${name}-''${f##*/open5gs-}"
    done
    # tests/app/5gc runs every 5G core network function in one process; it is
    # the "deploy all" entry point the image exposes for this variant.
    install -Dm755 tests/app/5gc "$out/bin/${name}"
  '';

  meta = (old.meta or { }) // {
    inherit description;
    homepage = "https://github.com/FlUxIuS/open5gs";
    mainProgram = name;
  };
})
