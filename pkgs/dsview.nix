# DSView (DreamSourceLab logic analyzer / oscilloscope GUI), source-built from
# the PentHertz fork (github.com/PentHertz/DSView) that RF Swift tracks, instead
# of the prebuilt amd64 .deb. Building from source means it also works on aarch64
# and macOS (the recipe is `platforms = unix`), not only x86_64 Linux.
#
# We reuse the nixpkgs source recipe (CMake + Qt5 + libsigrok4DSL /
# libsigrokdecode4DSL + Qt wrapping) and swap the source to the fork's v1.3.4
# tag. The fork's CMakeLists already requires CMake >= 3.5, so nixpkgs'
# cmake4 patch is unnecessary; its install patch does not apply (the fork's
# install section differs), so we make the equivalent fixes in postPatch:
# relative install prefixes, and forcing the (sandbox-guarded) udev-rules
# install so DSView's own DreamSourceLab.rules lands in the output. That means
# `rfswift nix udev` finds the official rule for DSLogic/DSCope (vendor 2a0e) -
# no separately maintained rule needed. macOS has no udev; the block is skipped.
{ lib, stdenv, dsview, fetchFromGitHub }:

dsview.overrideAttrs (o: {
  version = "1.3.4-penthertz";

  src = fetchFromGitHub {
    owner = "PentHertz";
    repo = "DSView";
    rev = "v1.3.4";
    hash = "sha256-/Poosd6oI6k1Q3X2QK2AcVC5Xrk07T9AFUC/CAte3Jw=";
  };

  # The nixpkgs patches target DreamSourceLab v1.3.2; the fork's CMakeLists
  # differs, so replace them with equivalent in-place fixes.
  patches = [ ];

  # libsigrok4DSL's C predates gcc-15 strictness (e.g. csv.c passes a runtime
  # buffer as a printf format). Keep nixpkgs' implicit-decl relaxation and also
  # stop -Werror from failing the build.
  env = (o.env or { }) // {
    NIX_CFLAGS_COMPILE = ((o.env or { }).NIX_CFLAGS_COMPILE or "")
      + " -Wno-error=format-security -Wno-error";
  };
  postPatch = (o.postPatch or "") + ''
    substituteInPlace CMakeLists.txt \
      --replace-quiet "/usr/share/applications" "share/applications" \
      --replace-quiet "if(IS_DIRECTORY /usr/lib/udev/rules.d)" "if(TRUE)" \
      --replace-quiet "DESTINATION /usr/lib/udev/rules.d RENAME" "DESTINATION lib/udev/rules.d RENAME"
  '';

  meta = (o.meta or { }) // {
    description = "DSView: DreamSourceLab logic analyzer / oscilloscope GUI (PentHertz fork, source build)";
    homepage = "https://github.com/PentHertz/DSView";
    platforms = lib.platforms.unix;
  };
})
