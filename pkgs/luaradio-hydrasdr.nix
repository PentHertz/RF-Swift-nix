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

  installPhase = ''
    runHook preInstall
    make install PREFIX=$out LUAJIT=${luajit}/bin/luajit || {
      mkdir -p $out/bin $out/share/luaradio
      cp -r radio $out/share/luaradio/ 2>/dev/null || true
      install -Dm755 luaradio $out/bin/luaradio 2>/dev/null || true
    }
    if [ -e $out/bin/luaradio ]; then
      wrapProgram $out/bin/luaradio \
        --prefix ${ldVar} : "${libraryPath}"
    fi
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
