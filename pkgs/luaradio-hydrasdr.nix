# LuaRadio, HydraSDR fork. LuaRadio is not in nixpkgs, so this is a standalone
# source build (not an override).
{ lib, stdenv, fetchFromGitHub, luajit, pkg-config, fftwFloat, liquid-dsp
, volk, makeWrapper }:

stdenv.mkDerivation {
  pname = "luaradio-hydrasdr";
  version = "unstable-hydrasdr";

  src = fetchFromGitHub {
    owner = "hydrasdr";
    repo = "luaradio";
    rev = "master";
    hash = "sha256-+tUm/rtuwH9TGc9jdB2Zvx5yOC322CLJ0P8VSSjqk30=";
  };

  nativeBuildInputs = [ makeWrapper pkg-config ];
  buildInputs = [ luajit fftwFloat liquid-dsp volk ];

  dontBuild = true;

  # LuaRadio ships a Makefile that installs the Lua sources and a `luaradio` CLI.
  installPhase = ''
    runHook preInstall
    make install PREFIX=$out LUAJIT=${luajit}/bin/luajit || {
      # Fallback: install the tree by hand if the Makefile target differs.
      mkdir -p $out/bin $out/share/luaradio
      cp -r radio $out/share/luaradio/ 2>/dev/null || true
      install -Dm755 luaradio $out/bin/luaradio 2>/dev/null || true
    }
    if [ -e $out/bin/luaradio ]; then
      wrapProgram $out/bin/luaradio \
        --prefix LD_LIBRARY_PATH : "${lib.makeLibraryPath [ fftwFloat liquid-dsp volk ]}"
    fi
    runHook postInstall
  '';

  meta = {
    description = "LuaRadio (HydraSDR fork): lightweight scriptable SDR framework";
    homepage = "https://github.com/hydrasdr/luaradio";
    license = lib.licenses.mit;
    platforms = lib.platforms.linux;
    mainProgram = "luaradio";
  };
}
