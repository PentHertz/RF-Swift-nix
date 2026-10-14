# targetedKerberoast (ShutdownRepo/targetedKerberoast): a single script that
# finds SPN-less user accounts it can write to, sets a temporary SPN, grabs the
# Kerberoast hash and removes the SPN again. Matches RF-Swift-images'
# targetedkerberoast_soft_install (venv with requirements.txt, wrapper
# /usr/local/bin/targetedKerberoast). requirements.txt (ldap3, pyasn1,
# impacket, rich, pycryptodome) all come from nixpkgs.
{ lib, stdenvNoCC, fetchFromGitHub, makeWrapper, python3 }:

let
  pyEnv = python3.withPackages (ps: with ps; [ ldap3 pyasn1 impacket rich pycryptodome ]);
in
stdenvNoCC.mkDerivation {
  pname = "targetedkerberoast";
  version = "unstable-2024-12-16";

  src = fetchFromGitHub {
    owner = "ShutdownRepo";
    repo = "targetedKerberoast";
    rev = "ebed0790002dfae503eb5e5525a0630f131fa117";
    hash = "sha256-PVXYZ1rWvoHOzhuGHOOieO98gdr+jBfw17AAerelHYU=";
  };

  nativeBuildInputs = [ makeWrapper ];
  dontBuild = true;

  # No chdir: the script only reads/writes paths given on the command line
  # (-U users file, -o output file), which must stay relative to the caller.
  installPhase = ''
    runHook preInstall
    install -Dm644 targetedKerberoast.py $out/share/targetedkerberoast/targetedKerberoast.py
    makeWrapper ${pyEnv}/bin/python3 $out/bin/targetedKerberoast \
      --add-flags "$out/share/targetedkerberoast/targetedKerberoast.py"
    # Lowercase alias. On a case-insensitive filesystem (macOS's default APFS)
    # the name already resolves to the wrapper and `ln` would fail on it.
    [ -e $out/bin/targetedkerberoast ] || ln -s targetedKerberoast $out/bin/targetedkerberoast
    runHook postInstall
  '';

  meta = {
    description = "Kerberoast accounts by temporarily setting SPNs on objects you can write to";
    homepage = "https://github.com/ShutdownRepo/targetedKerberoast";
    license = lib.licenses.gpl3Only;
    platforms = lib.platforms.unix;
    mainProgram = "targetedKerberoast";
  };
}
