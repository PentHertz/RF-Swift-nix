# ice9-bluetooth-sniffer: Bluetooth (BLE + Classic) sniffer for HackRF/BladeRF/USRP
# (mikeryan). CPU FFT path via FFTW (the optional Vulkan/glslang GPU path is off).
{ lib, stdenv, fetchFromGitHub, cmake, pkg-config, xxd
, liquid-dsp, fftwFloat, libpcap, hackrf, libbladeRF, uhd }:

stdenv.mkDerivation {
  pname = "ice9-bluetooth-sniffer";
  version = "1.4-unstable";

  src = fetchFromGitHub {
    owner = "mikeryan";
    repo = "ice9-bluetooth-sniffer";
    rev = "master";
    hash = "sha256-1MM05MB9TlyjLj/LG0xZ27EQPqCyzljpagZnUfiIkog=";
  };

  nativeBuildInputs = [ cmake pkg-config xxd ];
  buildInputs = [ liquid-dsp fftwFloat libpcap hackrf libbladeRF uhd ];

  # Upstream treats every non-32-bit-ARM Unix target as x86 and consequently
  # passes -msse4.1 on aarch64. Keep the explicit SIMD flags where they are
  # valid; AArch64 already includes Advanced SIMD in its baseline ISA.
  postPatch = ''
    substituteInPlace CMakeLists.txt \
      --replace-fail \
        'target_compile_options(ice9-bluetooth PRIVATE -msse4.1)' \
        $'if (CMAKE_SYSTEM_PROCESSOR MATCHES "x86_64|AMD64|i.86")\n      target_compile_options(ice9-bluetooth PRIVATE -msse4.1)\n    endif()' \
      --replace-fail \
        'target_compile_options(test_window PRIVATE -msse4.1)' \
        $'if (CMAKE_SYSTEM_PROCESSOR MATCHES "x86_64|AMD64|i.86")\n      target_compile_options(test_window PRIVATE -msse4.1)\n    endif()' \
      --replace-fail \
        'target_compile_options(test_pfbch2 PRIVATE -msse4.1)' \
        $'if (CMAKE_SYSTEM_PROCESSOR MATCHES "x86_64|AMD64|i.86")\n      target_compile_options(test_pfbch2 PRIVATE -msse4.1)\n    endif()'
  '';

  # gcc-15 header strictness on the vendored C sources.
  env.NIX_CFLAGS_COMPILE = "-Wno-error";
  cmakeFlags = [ "-DCMAKE_POLICY_VERSION_MINIMUM=3.5" ];

  meta = {
    description = "Bluetooth Classic + BLE sniffer for HackRF / BladeRF / USRP";
    homepage = "https://github.com/mikeryan/ice9-bluetooth-sniffer";
    license = lib.licenses.gpl2Plus;
    platforms = lib.platforms.linux;
    mainProgram = "ice9-bluetooth";
  };
}
