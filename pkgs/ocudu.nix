# OCUDU: 5G SA RAN stack (O-CU / O-DU), a srsRAN-derived project. RF Swift's
# telecom image installs it as the 5G standalone stack (replacing srsRAN Project).
# Large C++/CMake build; UHD + ZeroMQ radio backends enabled. The postPatch below
# fixes the one gcc-13/14/15 compile error (cpu_features.h to_array); with it the
# tree compiles and links cleanly. Upstream's install-time SBOM helper checks
# executable paths too early under Nix, so those entries are made optional below;
# the executables themselves are still installed and smoke-tested.
{ lib, stdenv, fetchFromGitLab, cmake, pkg-config, perl
, mbedtls, lksctp-tools, yaml-cpp, fftw, fftwFloat, boost, zeromq, openssl, uhd }:

stdenv.mkDerivation {
  pname = "ocudu";
  version = "unstable-2026";

  src = fetchFromGitLab {
    owner = "ocudu";
    repo = "ocudu";
    rev = "1f2d487e24f57672fe808e8d15bfd3698a518f47";
    hash = "sha256-DpqDtYimmHOkTDcW6wyoa14VJYE9fm2IlxExH3ff1mA=";
  };

  nativeBuildInputs = [ cmake pkg-config perl ];
  buildInputs = [ mbedtls lksctp-tools yaml-cpp fftw fftwFloat boost zeromq openssl uhd ];

  # cpu_features.h calls ocudu's own `to_array<cpu_feature>({...})` with a
  # braced-init-list; gcc-13/14/15 no longer deduce the array extent N from a
  # braced-init-list when T is given explicitly. Route it through a named
  # C-array so N deduces from a real array type (which every gcc accepts), and
  # seed it with the baseline feature of each architecture (SSE4.1 on x86_64,
  # NEON on aarch64 — the header's own enum is per-arch) so it is never empty.
  postPatch = ''
    f=include/ocudu/support/cpu_features.h
    perl -0777 -i -pe 's/constexpr auto cpu_features_included = to_array<cpu_feature>\(\{/static constexpr cpu_feature cpu_features_included_arr[] = {\n#ifdef __x86_64__\n    cpu_feature::sse4_1,\n#endif\n#ifdef __aarch64__\n    cpu_feature::neon,\n#endif/' "$f"
    perl -0777 -i -pe 's/\}\);\n\} \/\/ namespace detail/};\nconstexpr auto cpu_features_included = to_array(cpu_features_included_arr);\n} \/\/ namespace detail/' "$f"

    # cmake-sbom's per-target install scripts can run before the corresponding
    # target is visible at CMAKE_INSTALL_PREFIX in a Nix build. Treat only those
    # generated binary records as optional; this preserves the project SBOM and
    # lets CMake complete installation of the actual programs.
    perl -0777 -i -pe 's/(sbom_add\(\n        TARGET       \$\{ARGV\}\n        LICENSE      "LicenseRef-OCUDU")/$1\n        OPTIONAL/' CMakeLists.txt
  '';

  cmakeFlags = [
    "-DCMAKE_POLICY_VERSION_MINIMUM=3.5"
    "-DENABLE_UHD=ON"
    "-DENABLE_ZEROMQ=ON"
    "-DENABLE_FFTW=ON"
    # Optional debug/telemetry deps not needed for a functional build.
    "-DENABLE_BACKWARD=OFF"
    "-DBUILD_TESTS=OFF"
  ] ++ lib.optionals stdenv.hostPlatform.isAarch64 [
    # On aarch64 the build tunes with -mcpu=${MCPU} and the NEON CRC code
    # probes "-march=${MARCH}+crypto"; both default to "native", which gcc
    # rejects in the "+crypto" form and which would tune to the build host
    # anyway. Use the generic ARMv8 baseline: reproducible binaries and a valid
    # "-march=armv8-a+crypto" for the crypto-extension CRC path.
    "-DMCPU=generic"
    "-DMARCH=armv8-a"
  ];
  # SSE4.1 is the x86 baseline the SIMD code expects; aarch64 has NEON by default.
  env.NIX_CFLAGS_COMPILE = "-Wno-error" + lib.optionalString stdenv.hostPlatform.isx86_64 " -msse4.1";

  meta = {
    description = "5G SA RAN stack (O-CU / O-DU), srsRAN-derived (used by RF Swift for 5G standalone)";
    homepage = "https://gitlab.com/ocudu/ocudu";
    license = lib.licenses.agpl3Plus;
    # x86_64 and aarch64 (the srsRAN team tests both; the images build arm64).
    platforms = [ "x86_64-linux" "aarch64-linux" ];
  };
}
