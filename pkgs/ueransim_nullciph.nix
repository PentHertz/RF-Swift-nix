# ueransim_nullciph: FlUxIuS's "nullciph" branch of UERANSIM — a UE/gNB
# simulator patched to negotiate null ciphering, built by the
# telecom_4Gto5G_extended image for core-network training labs. Same recipe as
# nixpkgs' ueransim, different source; the programs are installed with a
# ueransim_nullciph- prefix (ueransim_nullciph-nr-gnb, -nr-ue, -nr-cli, ...)
# so the patched build is unmistakable next to the stock nr-* binaries.
{ lib, fetchFromGitHub, ueransim }:

ueransim.overrideAttrs (old: {
  pname = "ueransim_nullciph";
  version = "${old.version}-nullciph";
  src = fetchFromGitHub {
    owner = "FlUxIuS";
    repo = "UERANSIM";
    rev = "daaea697372c0a5ee7cf8150ec1899268e82d76b"; # branch nullciph
    hash = "sha256-knt35XtP6F5mP5MIp5GfMl0CU3WCkpLlbJlIm/bIE5g=";
  };
  postInstall = (old.postInstall or "") + ''
    for b in "$out"/bin/nr-*; do
      mv "$b" "$out/bin/ueransim_nullciph-$(basename "$b")"
    done
  '';
  meta = (old.meta or { }) // {
    description = "UERANSIM patched for null ciphering (FlUxIuS training fork); programs prefixed ueransim_nullciph-";
    homepage = "https://github.com/FlUxIuS/UERANSIM";
    mainProgram = "ueransim_nullciph-nr-gnb";
  };
})
