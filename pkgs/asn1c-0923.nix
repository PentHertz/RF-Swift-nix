# asn1c 0.9.23 - the exact ASN.1 compiler OpenBTS-UMTS's RRC codec was generated
# against (its README pins v0.9.23; nixpkgs ships 0.9.29, whose renamed skeleton
# macros/APIs break the build). Built from the tarball bundled in the OpenBTS-UMTS
# repo. Legacy 2014-era C, so relax the modern gcc-15 diagnostics.
{ lib, stdenv, fetchurl, flex, bison, perl }:

stdenv.mkDerivation {
  pname = "asn1c";
  version = "0.9.23";

  src = fetchurl {
    url = "https://github.com/PentHertz/OpenBTS-UMTS/raw/e7baf152e40c670bcc3a9f12e7099417b8bb4f88/asn1c-0.9.23.tar.gz";
    hash = "sha256-tu+z7cyK46xSBR+/Yez5i+NcGc1SEIvK3Nn4ZyCQcdc=";
  };

  sourceRoot = "vlm-asn1c-0959ffb";

  nativeBuildInputs = [ flex bison perl ];

  # The example ASN.1 sources are generated during `make` by Perl scripts whose
  # upstream shebang is `/usr/bin/env perl`. Pure Nix builders have no /usr/bin.
  postPatch = ''
    patchShebangs .
  '';

  # C23 (gcc-15 default) rejects the K&R-era constructs this vintage uses.
  env.NIX_CFLAGS_COMPILE = toString [
    "-std=gnu89"
    "-fcommon"
    "-Wno-error"
    "-Wno-implicit-int"
    "-Wno-implicit-function-declaration"
    "-Wno-int-conversion"
    "-Wno-return-mismatch"
  ];

  # This vintage has printf(var) calls that trip nixpkgs' default
  # -Werror=format-security hardening.
  hardeningDisable = [ "format" ];

  enableParallelBuilding = true;
  doCheck = false;

  meta = {
    description = "ASN.1 compiler v0.9.23 (pinned for OpenBTS-UMTS's RRC codec)";
    homepage = "https://github.com/vlm/asn1c";
    license = lib.licenses.bsd2;
    mainProgram = "asn1c";
    platforms = [ "x86_64-linux" ];
  };
}
