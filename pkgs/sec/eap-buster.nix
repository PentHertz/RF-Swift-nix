# EAP_buster (blackarrowsec/EAP_buster): bash script that lists which EAP methods
# the RADIUS server behind a WPA-Enterprise AP accepts, by running wpa_supplicant
# once per method with a known identity. Matches RF-Swift-images'
# eap_buster_soft_install (wrapper `EAP_buster` running ./EAP_buster.sh from its
# checkout).
#
# The script works in its own directory: it rewrites the EAP_config/*.conf
# templates in place (sed -i), writes user.pem/user.key there and logs to
# ./<ESSID>/. The store is read-only, so the launcher refreshes a writable copy
# in $EAP_BUSTER_DIR (default $XDG_DATA_HOME/EAP_buster, i.e. ~/.local/share;
# /root/.local/share under sudo) and execs the script from there - logs land in
# $EAP_BUSTER_DIR/<ESSID>/.
{ lib, stdenvNoCC, fetchFromGitHub, makeWrapper, runtimeShell
, coreutils, findutils, gnugrep, gnused, iproute2, iw, openssl, psmisc
, xxd, wpa_supplicant }:

stdenvNoCC.mkDerivation {
  pname = "eap-buster";
  version = "unstable-2023-10-27";

  src = fetchFromGitHub {
    owner = "blackarrowsec";
    repo = "EAP_buster";
    rev = "99889eee267012f0581e59a074b9539e7d92a1b0";
    hash = "sha256-VV55e//rl+StDp06OGDtWtiyxjyxEMDntkSMEEUVdks=";
  };

  nativeBuildInputs = [ makeWrapper ];
  dontConfigure = true;
  dontBuild = true;

  installPhase = ''
    runHook preInstall
    install -Dm755 EAP_buster.sh $out/share/EAP_buster/EAP_buster.sh
    cp -r EAP_config $out/share/EAP_buster/
    install -Dm644 README.md $out/share/doc/EAP_buster/README.md
    patchShebangs $out/share/EAP_buster/EAP_buster.sh

    # Launcher: $out is baked in now; \$ escapes keep the rest for runtime, and
    # ''${ escapes Nix antiquotation.
    mkdir -p $out/bin
    cat > $out/bin/EAP_buster <<EOF
    #!${runtimeShell}
    set -e
    share="$out/share/EAP_buster"
    dir="\''${EAP_BUSTER_DIR:-\''${XDG_DATA_HOME:-\$HOME/.local/share}/EAP_buster}"
    mkdir -p "\$dir"
    # Fresh, writable script + templates each run (the script edits them in place).
    rm -rf "\$dir/EAP_config"
    cp -r --no-preserve=mode "\$share/EAP_config" "\$dir/"
    install -m755 "\$share/EAP_buster.sh" "\$dir/EAP_buster.sh"
    exec "\$dir/EAP_buster.sh" "\$@"
    EOF
    chmod +x $out/bin/EAP_buster
    wrapProgram $out/bin/EAP_buster \
      --prefix PATH : ${lib.makeBinPath [
        coreutils findutils gnugrep gnused iproute2 iw openssl psmisc xxd
        wpa_supplicant
      ]}
    ln -s EAP_buster $out/bin/eap_buster
    runHook postInstall
  '';

  meta = {
    description = "Lists the EAP methods supported by the RADIUS server behind a WPA-Enterprise AP";
    homepage = "https://github.com/blackarrowsec/EAP_buster";
    license = lib.licenses.mit;
    platforms = lib.platforms.linux;
    mainProgram = "EAP_buster";
  };
}
