# OpenAirInterface 5G RAN: the gNB (nr-softmodem, plus the nr-cuup CU-UP
# process) and the 5G NR UE (nr-uesoftmodem) soft-modems with the USRP (UHD)
# radio. Matches RF-Swift-images' openairinterface5g_soft_install (the
# telecom_5G_oai image): tag v2.4.0, asn1c from the mouse07410 fork at the
# commit OAI pins, SIMDE at OAI's pinned commit, then
# `build_oai --gNB --nrUE -w USRP --ninja`.
#
# build_oai is an apt-centric wrapper around CMake, so its CMake call is
# reproduced here instead: same options (-DOAI_USRP=ON, RelWithDebInfo) and
# the same ninja target list. OAI has no install rules; the binaries go to
# $out/bin and the runtime plugins it dlopen()s by bare name (liboai_device.so
# -> liboai_usrpdevif.so, librfsimulator.so, libldpc.so, libdfts.so,
# libparams_libconfig.so, ...) to $out/lib/openairinterface5g, which is added
# to every ELF's RUNPATH. LD_LIBRARY_PATH still takes precedence, as upstream.
{ lib, stdenv, stdenvNoCC, fetchFromGitLab, fetchFromGitHub, fetchurl
, autoreconfHook, bison, flex, perl
, cmake, ninja, pkg-config, xxd, patchelf
, uhd, boost, libconfig, lksctp-tools, openssl, blas, lapack, yaml-cpp, libcap, zlib
}:

let
  # OAI drives asn1c with flags only the mouse07410 fork has (-gen-APER,
  # -no-gen-UPER/JER/BER/OER); nixpkgs' asn1c is upstream vlm 0.9.29. Same
  # commit and CFLAGS as OAI's install_asn1c_from_source (the fork's newer
  # vlm_master breaks F1/NG per OAI).
  asn1c = stdenv.mkDerivation {
    pname = "asn1c-mouse07410";
    version = "0.9.29-unstable-2024-04-05";

    src = fetchFromGitHub {
      owner = "mouse07410";
      repo = "asn1c";
      rev = "940dd5fa9f3917913fd487b13dfddfacd0ded06e";
      hash = "sha256-p9MAkwzeAL3I3PL0o15ABMluoorU1gcJbmU+s9DgPiY=";
    };

    nativeBuildInputs = [ autoreconfHook bison flex perl ];

    env.CFLAGS = "-O2 -fno-strict-aliasing";

    enableParallelBuilding = true;
    doCheck = false;
  };

  # Header-only; OAI includes <simde/...> and installs the repo root as
  # /usr/include/simde. Pinned to OAI's "last working commit" (newer than
  # nixpkgs' simde 0.8.2).
  simde = stdenvNoCC.mkDerivation {
    pname = "simde-no-tests";
    version = "unstable-2025-02-14";

    src = fetchFromGitHub {
      owner = "simd-everywhere";
      repo = "simde-no-tests";
      rev = "c7f26b73ba8e874b95c2cec2b497826ad2188f68";
      hash = "sha256-vDeQf9P3hZo1EnZsXaLIl1jsLD8mRdMYhJeyzxEiZS8=";
    };

    dontConfigure = true;
    dontBuild = true;
    installPhase = ''
      mkdir -p $out/include
      cp -r . $out/include/simde
    '';
  };

  # cmake_targets/CPM.cmake downloads CPM at configure time. Only CPM itself is
  # needed: every CPMAddPackage() call is behind an option left off here, or a
  # fallback for a dependency (yaml-cpp) provided below.
  cpm = fetchurl {
    url = "https://github.com/cpm-cmake/CPM.cmake/releases/download/v0.40.1/CPM.cmake";
    hash = "sha256-EXy/JxFXLxE7qyYpM+tRh7CM/Abc4HFKHulPIYPdw+w=";
  };

  # OAI compiles with -march=native (stripped by the Nix cc-wrapper, and not
  # reproducible anyway) while hard-defining SIMDE_X86_{AVX,FMA,F16C,PCLMUL}_NATIVE
  # and calling _mm_clmulepi64_si128 directly (CRC). Pin a portable baseline
  # instead: x86-64-v3 (Haswell+/Zen: AVX2, FMA) plus PCLMUL, which v3 does not
  # include, with AVX2 code paths on and AVX-512 off; OAI's own cross-compile
  # target (armv8.2-a) on aarch64.
  march = if stdenv.hostPlatform.isx86_64 then "x86-64-v3 -mpclmul" else "armv8.2-a";

  # The build_oai --gNB --nrUE -w USRP target list, plus the extra modules it
  # always adds.
  targets = [
    "nr-softmodem" "nr-cuup" "nr-uesoftmodem" "oai_usrpdevif"
    "params_libconfig" "coding" "rfsimulator" "dfts" "params_yaml" "vrtsim" "rf_emulator"
  ];
in
stdenv.mkDerivation (finalAttrs: {
  pname = "openairinterface5g";
  version = "2.4.0";

  src = fetchFromGitLab {
    domain = "gitlab.eurecom.fr";
    owner = "oai";
    repo = "openairinterface5g";
    rev = "v${finalAttrs.version}";
    hash = "sha256-iX9GfGTz2bGMSlfE8GaEn+j3a9kcZByjSeXW7TLJv0o=";
  };

  postPatch = ''
    echo 'include(${cpm})' > cmake_targets/CPM.cmake

    substituteInPlace CMakeLists.txt \
      --replace-fail '-march=native' '-march=${march}' \
      --replace-fail '-mcpu=native' '-march=${march}' \
      --replace-fail 'file(STRINGS "/proc/cpuinfo" CPUPART REGEX "CPU part" LIMIT_COUNT 1)' 'set(CPUPART "")' \
      --replace-fail 'set(debugOpt "-ggdb2 ' 'set(debugOpt "'

    # usrp_lib.cpp calls boost::this_thread::sleep but only links libuhd.
    # Ubuntu's libuhd drags libboost_thread in; nixpkgs' does not, so dlopen()
    # of liboai_usrpdevif.so fails with an undefined boost::this_thread symbol.
    cat >> radio/USRP/CMakeLists.txt <<'EOF'
    find_package(Boost REQUIRED COMPONENTS thread)
    target_link_libraries(oai_usrpdevif PRIVATE Boost::thread)
    EOF
  '';
  # (The -ggdb2 substitution drops debug info from RelWithDebInfo: the output
  # is stripped anyway, and full debug info for OAI costs GBs of build space.)

  nativeBuildInputs = [ cmake ninja pkg-config xxd patchelf ];
  buildInputs = [
    asn1c simde uhd boost libconfig lksctp-tools openssl blas lapack yaml-cpp libcap zlib
  ];

  cmakeBuildType = "RelWithDebInfo";
  cmakeFlags = [
    "-DASN1C_EXEC=${asn1c}/bin/asn1c"
    "-DOAI_USRP=ON"
    "-DCCACHE_ACTIVE=OFF"
  ] ++ lib.optionals stdenv.hostPlatform.isx86_64 [
    "-DAVX2=ON"
    "-DAVX512=OFF"
  ];

  # The plugins rely on lazy binding: librfsimulator.so references a gNB-only
  # function (nr_update_sib19) and libvrtsim.so the optional taps client, so
  # with nixpkgs' default -z now nr-uesoftmodem cannot dlopen() --rfsim / vrtsim.
  hardeningDisable = [ "bindnow" ];

  ninjaFlags = targets;
  enableParallelBuilding = true;

  installPhase = ''
    runHook preInstall
    install -Dm755 -t $out/bin nr-softmodem nr-cuup nr-uesoftmodem
    mkdir -p $out/lib/openairinterface5g
    cp -P lib*.so $out/lib/openairinterface5g/
    mkdir -p $out/share/openairinterface5g
    cp -r ../targets/PROJECTS/GENERIC-NR-5GC/CONF $out/share/openairinterface5g/conf
    runHook postInstall
  '';

  # After fixup's --shrink-rpath (which drops dirs no DT_NEEDED entry uses).
  postFixup = ''
    for f in $out/bin/* $out/lib/openairinterface5g/*.so; do
      [ -L "$f" ] || patchelf --add-rpath $out/lib/openairinterface5g "$f"
    done
  '';

  meta = {
    description = "OpenAirInterface 5G RAN: gNB and NR UE soft-modems (USRP/UHD radio)";
    homepage = "https://openairinterface.org/";
    changelog = "https://gitlab.eurecom.fr/oai/openairinterface5g/-/blob/v${finalAttrs.version}/CHANGELOG.md";
    # OAI Public License v1.1: Apache-2.0 based, with a FRAND patent clause
    # that makes it non-free by OSI/FSF standards (redistributable).
    license = {
      fullName = "OAI Public License v1.1";
      url = "https://openairinterface.org/legal/oai-public-license/";
      free = false;
      redistributable = true;
    };
    platforms = [ "x86_64-linux" ];
    mainProgram = "nr-softmodem";
  };
})
