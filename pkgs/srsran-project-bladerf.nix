# srsran-project-bladerf: FlUxIuS's srsRAN Project (5G SA gNB) fork adapted to
# drive a bladeRF — the telecom_5G_bladerf image's RAN. srsRAN Project only
# speaks UHD, so the bladeRF reaches it through SoapyUHD's UHD-side bridge and
# the matching SoapyBladeRF fork (soapybladerf-srsran); the fork's own change
# is in the UHD radio device layer. Built like OCUDU (same code lineage): UHD +
# ZeroMQ + FFTW backends, no vendor math libraries, no tests.
{ lib, stdenv, fetchFromGitHub, cmake, pkg-config, perl
, mbedtls, lksctp-tools, yaml-cpp, fftw, fftwFloat, boost, zeromq, openssl, uhd }:

stdenv.mkDerivation {
  pname = "srsran-project-bladerf";
  version = "unstable-fluxius";

  src = fetchFromGitHub {
    owner = "FlUxIuS";
    repo = "srsRAN_Project_bladerf";
    rev = "7b46be942c260fff5598fb34adae5c45c1a7009c";
    hash = "sha256-rWHBpxT5R86SeameEJcuwL0cGD+m4NlHiJ4miZJvkas=";
  };

  nativeBuildInputs = [ cmake pkg-config perl ];
  buildInputs = [ mbedtls lksctp-tools yaml-cpp fftw fftwFloat boost zeromq openssl uhd ];

  # Same gcc-13+ to_array<cpu_feature>({...}) deduction failure as OCUDU
  # (shared code); the substitution is a no-op if this tree no longer has it.
  postPatch = ''
    f=include/srsran/support/cpu_features.h
    if [ -f "$f" ]; then
      perl -0777 -i -pe 's/constexpr auto cpu_features_included = to_array<cpu_feature>\(\{/static constexpr cpu_feature cpu_features_included_arr[] = {\n#ifdef __x86_64__\n    cpu_feature::sse4_1,\n#endif\n#ifdef __aarch64__\n    cpu_feature::neon,\n#endif/' "$f"
      perl -0777 -i -pe 's/\}\);\n\} \/\/ namespace detail/};\nconstexpr auto cpu_features_included = to_array(cpu_features_included_arr);\n} \/\/ namespace detail/' "$f"
    fi
  '';

  cmakeFlags = [
    "-DCMAKE_POLICY_VERSION_MINIMUM=3.5"
    "-DENABLE_UHD=ON"
    "-DENABLE_ZEROMQ=ON"
    "-DENABLE_FFTW=ON"
    "-DENABLE_MKL=OFF"
    "-DENABLE_ARMPL=OFF"
    "-DENABLE_BACKWARD=OFF"
    "-DENABLE_WERROR=OFF"
    "-DBUILD_TESTS=OFF"
  ];
  env.NIX_CFLAGS_COMPILE = "-Wno-error" + lib.optionalString stdenv.hostPlatform.isx86_64 " -msse4.1";

  meta = {
    description = "srsRAN Project 5G SA gNB, bladeRF fork (via SoapyUHD + SoapyBladeRF_srsran)";
    homepage = "https://github.com/FlUxIuS/srsRAN_Project_bladerf";
    license = lib.licenses.agpl3Plus;
    platforms = lib.platforms.linux;
  };
}
