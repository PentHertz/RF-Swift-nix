# telecom-wireshark-dissectors: the two Lua dissectors the
# telecom_4Gto5G_extended image drops into Wireshark's plugin directory - # UERANSIM's RLS (radio link simulation) dissector and SCAT's baseband-diag
# dissector (PentHertz fork). Wireshark's store path is immutable under Nix, so
# they are shipped under share/wireshark/plugins; load them from Wireshark's
# personal plugin folder (~/.local/lib/wireshark/plugins) or via
# `wireshark -X lua_script:<file>`, as the README in the package explains.
{ lib, stdenvNoCC, fetchurl }:

let
  rls = fetchurl {
    url = "https://raw.githubusercontent.com/aligungr/UERANSIM/v3.3.0/tools/rls-wireshark-dissector.lua";
    hash = "sha256-81sO0MOyLJhSIgJElwQGqDB0dF3lAChDzuxhHad1m+Q=";
  };
  scat = fetchurl {
    url = "https://raw.githubusercontent.com/PentHertz/scat/refs/heads/master/wireshark/scat.lua";
    hash = "sha256-0iC5P+6zWvzeUpBxTt2XIQc2lqviXf9v/12l1VW5L3k=";
  };
in
stdenvNoCC.mkDerivation {
  pname = "telecom-wireshark-dissectors";
  version = "2026-08-29";
  dontUnpack = true;

  installPhase = ''
    runHook preInstall
    d=$out/share/wireshark/plugins
    mkdir -p $d
    install -Dm644 ${rls} $d/rls-wireshark-dissector.lua
    install -Dm644 ${scat} $d/scat.lua
    cat > $out/share/wireshark/README-rfswift-dissectors.txt <<EOF
    Wireshark Lua dissectors shipped by RF Swift (telecom environment):
      rls-wireshark-dissector.lua  UERANSIM RLS radio-link-simulation frames
      scat.lua                     SCAT baseband diagnostic captures
    Wireshark cannot load plugins from the immutable Nix store path, so link
    them into your personal plugin folder once:
      mkdir -p ~/.local/lib/wireshark/plugins
      ln -sf $d/*.lua ~/.local/lib/wireshark/plugins/
    or pass one explicitly: wireshark -X lua_script:$d/scat.lua
    EOF
    sed -i 's/^    //' $out/share/wireshark/README-rfswift-dissectors.txt
    runHook postInstall
  '';

  meta = {
    description = "UERANSIM RLS and SCAT Lua dissectors for Wireshark (telecom environment)";
    license = lib.licenses.gpl3Plus;
    platforms = lib.platforms.unix;
  };
}
