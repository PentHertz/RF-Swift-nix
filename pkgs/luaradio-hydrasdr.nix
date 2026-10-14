# LuaRadio, HydraSDR fork. LuaRadio has no build step: it is LuaJIT plus the
# `radio` Lua tree, and every device backend is opened at run time with
# ffi.load by bare library name (librtlsdr.so, libhackrf.so, libairspy.so,
# libhydrasdr.so, libbladeRF.so, libuhd.so, libSoapySDR.so ...). Nothing links
# them, so the wrapper has to put those libraries where the dynamic loader
# finds them. The unversioned names ffi.load asks for live in the -dev outputs
# of split packages, hence both lib and dev directories go on the path.
{ lib, stdenv, fetchFromGitHub, luajit, pkg-config, fftwFloat, liquid-dsp
, volk, makeWrapper
, rtl-sdr, hackrf, airspy, airspyhf, libhydrasdr, libbladeRF, uhd
, soapysdr-with-plugins }:

let
  available = p: lib.meta.availableOn stdenv.hostPlatform p;
  deviceLibs = builtins.filter available
    [ rtl-sdr hackrf airspy airspyhf libhydrasdr libbladeRF uhd soapysdr-with-plugins ];
  runtimeLibs = [ fftwFloat liquid-dsp volk ] ++ deviceLibs;
  libraryPath = lib.concatMapStringsSep ":"
    (p: "${lib.getLib p}/lib:${lib.getDev p}/lib") runtimeLibs;
  ldVar = if stdenv.hostPlatform.isDarwin then "DYLD_LIBRARY_PATH" else "LD_LIBRARY_PATH";
in
stdenv.mkDerivation {
  pname = "luaradio-hydrasdr";
  version = "unstable-hydrasdr";

  src = fetchFromGitHub {
    owner = "hydrasdr";
    repo = "luaradio";
    rev = "7db1ae930f590b70715719c1f3e1cbf4308a8a88";
    hash = "sha256-+tUm/rtuwH9TGc9jdB2Zvx5yOC322CLJ0P8VSSjqk30=";
  };

  nativeBuildInputs = [ makeWrapper pkg-config ];
  buildInputs = [ luajit fftwFloat liquid-dsp volk ];

  dontBuild = true;

  # Upstream has no install target (the only Makefile is embed/'s, for the
  # optional C library): LuaRadio is the `radio` Lua tree plus the `luaradio`
  # launcher, which `require`s the tree through LuaJIT's package.path. Install
  # the tree in the standard Lua layout and put it on LUA_PATH; the trailing
  # ";;" keeps LuaJIT's default path (its own jit.* modules) after it.
  installPhase = ''
    runHook preInstall
    mkdir -p $out/share/lua/5.1
    cp -r radio $out/share/lua/5.1/
    install -Dm755 luaradio $out/bin/luaradio
    wrapProgram $out/bin/luaradio \
      --run 'export LUA_PATH="'"$out"'/share/lua/5.1/?.lua;'"$out"'/share/lua/5.1/?/init.lua;''${LUA_PATH:-;}"' \
      --prefix ${ldVar} : "${libraryPath}"
    runHook postInstall
  '';

  passthru.deviceLibraries = deviceLibs;

  meta = {
    description = "LuaRadio (HydraSDR fork): lightweight scriptable SDR framework, with its device backends on the library path";
    homepage = "https://github.com/hydrasdr/luaradio";
    license = lib.licenses.mit;
    platforms = lib.platforms.unix;
    mainProgram = "luaradio";
  };
}
