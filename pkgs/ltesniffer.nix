# LTESniffer: passive LTE downlink/uplink sniffer (PDCCH/PDSCH/PUSCH decoding to
# pcap) built on FALCON and an srsRAN 4G fork. Matches RF-Swift-images'
# LTESniffer_soft_install (telecom_ltesniffer image): default branch, cmake +
# make, build/src/LTESniffer exposed as `LTESniffer`.
#
# Upstream's CMakeLists clones two subprojects at configure time (no network
# in the Nix sandbox), so they are handled here instead:
# - srsRAN: the ShaoPaoLao/srsRAN2 fork (srsRAN 4G 21.10 based) cloned from
#   its `master` branch; pinned below and dropped where upstream expects it.
# - c-mnalib: only linked by FALCON's falcon_meas library, which LTESniffer
#   does not use, so it is skipped (it would pull in libudev and curl).
{ lib, stdenv, fetchFromGitHub, cmake, pkg-config, fftwFloat, mbedtls, boost
, uhd, libbladeRF, glib, lksctp-tools }:

let
  srsran2 = fetchFromGitHub {
    owner = "ShaoPaoLao";
    repo = "srsRAN2";
    rev = "0acc79d3fe5b153a18b62e8ef5af1a0fb2327a18";
    hash = "sha256-R3pV3zv8Ya6JYCDyHtCk5Gct1q/J6acuyN1uM9JOq58=";
  };
in
stdenv.mkDerivation {
  pname = "ltesniffer";
  version = "unstable-2024-10-24";

  src = fetchFromGitHub {
    owner = "SysSec-KAIST";
    repo = "LTESniffer";
    rev = "a694803082017ac2b349e6b113940e8b9ba2fe5b";
    hash = "sha256-PUYyrNJTiNgUslk9m/IuDfxmqIufnZOuiKuarJ/82eE=";
  };

  postUnpack = ''
    cp -r ${srsran2} $sourceRoot/srsRAN-src
    chmod -R u+w $sourceRoot/srsRAN-src
  '';

  postPatch = ''
    # Use the pinned srsRAN tree instead of the configure-time git clone: the
    # download sub-project becomes an empty one, and the tree is read from the
    # source dir rather than the build dir.
    echo 'cmake_minimum_required(VERSION 3.10)
    project(srsRAN-download NONE)' > external/cmake/srsRAN.CMakeLists.txt.in
    substituteInPlace CMakeLists.txt \
      --replace-fail '"''${CMAKE_BINARY_DIR}/srsRAN-src' '"''${CMAKE_SOURCE_DIR}/srsRAN-src' \
      --replace-fail 'find_package(CMNALIB)' 'set(CMNALIB_FOUND TRUE)'

    # boost 1.89 removed the boost_system stub library (same fix as nixpkgs'
    # srsran); "  system" only appears in BOOST_REQUIRED_COMPONENTS.
    sed -i '/^  system$/d' CMakeLists.txt
    substituteInPlace srsRAN-src/cmake/modules/FindUHD.cmake --replace-fail \
      'uhd boost_program_options boost_system' 'uhd boost_program_options'

    # C++-style `auto` in a C99 file is an implicit int, an error since GCC 14.
    substituteInPlace lib/src/phy/falcon_phch/falcon_dci.c \
      --replace-fail 'for (auto i = 0;' 'for (int i = 0;'
    # Uses srsRAN's ERROR() macro without including its header; implicit
    # function declarations are errors since GCC 14.
    substituteInPlace lib/src/phy/falcon_phch/ul_sniffer_pusch.c \
      --replace-fail '#include "falcon/phy/falcon_phch/ul_sniffer_pusch.h"' \
        '#include "falcon/phy/falcon_phch/ul_sniffer_pusch.h"
    #include "srsran/phy/utils/debug.h"'
    # Missing <string>/<array> includes, no longer pulled in transitively by
    # newer libstdc++.
    substituteInPlace srsRAN-src/lib/include/srsran/radio/channel_mapping.h \
      --replace-fail '#include <mutex>' '#include <mutex>
    #include <string>'
    substituteInPlace srsRAN-src/lib/include/srsran/srslog/bundled/fmt/core.h \
      --replace-fail '#include <cstring>' '#include <array>
    #include <cstring>'

    # srsRAN adds -Werror; this 2021-era code trips newer GCC warnings.
    substituteInPlace srsRAN-src/CMakeLists.txt \
      --replace-fail 'set(CMAKE_C_FLAGS "''${CMAKE_C_FLAGS} -Werror")' "" \
      --replace-fail 'set(CMAKE_CXX_FLAGS "''${CMAKE_CXX_FLAGS} -Werror")' ""
  '';

  nativeBuildInputs = [ cmake pkg-config ];
  # glib is only checked for by the top-level CMakeLists (for c-mnalib);
  # lksctp-tools is required to configure srsRAN's (unbuilt) tests.
  buildInputs = [ fftwFloat mbedtls boost uhd libbladeRF glib lksctp-tools ];

  # srsRAN and LTESniffer declare cmake_minimum_required < 3.5, which CMake 4
  # rejects; the env var also covers the cmake -P scripts run at build time.
  env.CMAKE_POLICY_VERSION_MINIMUM = "3.5";

  cmakeFlags = [
    # UHD 4.10+ headers need C++17 (srsRAN's own -std=c++11 comes earlier on
    # the command line and is overridden; LTESniffer's sources keep c++11).
    (lib.cmakeFeature "CMAKE_CXX_STANDARD" "17")
    # LTESniffer would otherwise get an RPATH into the build tree for
    # libsrsran_rf.so; $out/lib is added in installPhase instead.
    (lib.cmakeBool "CMAKE_SKIP_BUILD_RPATH" true)
    # Radios: UHD (USRP, what the image targets) and bladeRF, the two the
    # README names. No Soapy/ZeroMQ/Sidekiq, no srsGUI, no PC/SC.
    (lib.cmakeBool "ENABLE_UHD" true)
    (lib.cmakeBool "ENABLE_BLADERF" true)
    (lib.cmakeBool "ENABLE_SOAPYSDR" false)
    (lib.cmakeBool "ENABLE_ZEROMQ" false)
    (lib.cmakeBool "ENABLE_SKIQ" false)
    (lib.cmakeBool "ENABLE_GUI" false)
    (lib.cmakeBool "ENABLE_HARDSIM" false)
    # Only srsRAN's libraries are needed, not srsUE/srsENB/srsEPC.
    (lib.cmakeBool "ENABLE_SRSUE" false)
    (lib.cmakeBool "ENABLE_SRSENB" false)
    (lib.cmakeBool "ENABLE_SRSEPC" false)
  ] ++ lib.optionals stdenv.hostPlatform.isx86_64 [
    # Upstream compiles with -march=native and probes SSE/AVX by running test
    # programs on the build machine, which makes the binary depend on the
    # builder's CPU. Pin AVX2+FMA (x86-64-v3, what upstream's probe picks on
    # any CPU that can decode in real time; srsRAN's SIMD kernels need it for
    # speed) and leave AVX-512 off so the binary runs on common desktop and
    # laptop CPUs.
    (lib.cmakeFeature "GCC_ARCH" "x86-64-v3")
    (lib.cmakeBool "HAVE_SSE" true)
    (lib.cmakeBool "HAVE_AVX" true)
    (lib.cmakeBool "HAVE_AVX2" true)
    (lib.cmakeBool "HAVE_FMA" true)
    (lib.cmakeBool "HAVE_AVX512" false)
    (lib.cmakeBool "ENABLE_AVX512" false)
  ];

  # Build only the sniffer and the libraries it links, not srsRAN's tests and
  # examples (which are always part of `all`).
  buildFlags = [ "LTESniffer" ];
  enableParallelBuilding = true;

  installPhase = ''
    runHook preInstall
    install -Dm755 src/LTESniffer $out/bin/LTESniffer
    # srsRAN's RF layer (UHD/bladeRF drivers) is a shared library.
    mkdir -p $out/lib
    cp -P srsRAN-build/lib/src/phy/rf/libsrsran_rf.so* $out/lib/
    patchelf --add-rpath $out/lib $out/bin/LTESniffer
    # Example pcaps and the Wireshark (DLT_USER / mac-lte) setup guide the
    # README points to.
    mkdir -p $out/share/ltesniffer
    cp -r ../pcap_file_example $out/share/ltesniffer/
    runHook postInstall
  '';

  meta = {
    description = "Open-source LTE downlink/uplink eavesdropper (passive PDCCH/PDSCH/PUSCH decoder)";
    homepage = "https://github.com/SysSec-KAIST/LTESniffer";
    license = lib.licenses.agpl3Plus;
    platforms = [ "x86_64-linux" ];
    mainProgram = "LTESniffer";
  };
}
