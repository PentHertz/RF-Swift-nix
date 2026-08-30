# gr-htra: dedicated GNU Radio OOT source block for Harogic real-time spectrum
# analyzers (HAROGIC-Technologies/gr-htra), matching RF-Swift-images'
# grhtra_grmod_install. It links the Harogic HTRA API SDK.
#
# The upstream CMake accepts HTRAAPI_INCLUDE_DIR and HTRAAPI_LIBRARY cache
# variables (the path install.sh normally sets), builds the HTRAAPI::htraapi
# imported target from them, and inspects the library with `file` to reject a
# foreign-arch SDK. We point those variables at the Nix harogic-htra-sdk out
# (libhtraapi.so + htra_api.h) and provide `file` for that check.
#
# x86_64-linux only: the images gate ARM out because the module hits an LTO
# segfault there (the grhtra_grmod_install ARM branch is commented "TODO"), and
# the HTRA SDK ships x86_64 + aarch64 host libraries only.
{ lib, fetchFromGitHub, gnuradioPackages, cmake, pkg-config, file
, boost, spdlog, gmp, volk, harogic-htra-sdk, python3Packages }:

gnuradioPackages.mkDerivation {
  pname = "gr-htra";
  version = "unstable-harogic";

  src = fetchFromGitHub {
    owner = "HAROGIC-Technologies";
    repo = "gr-htra";
    rev = "2237f01ad8ab5ed889b12331dd5519b65eec1677";
    hash = "sha256-tUtcQNe365gOJ1xSR/LYJyztPCkMaeFxR/+phY+25aM=";
  };

  # `file` is required by the CMake HTRA API arch check.
  nativeBuildInputs = [ cmake pkg-config file python3Packages.pybind11 ];
  buildInputs = [ boost spdlog gmp volk harogic-htra-sdk python3Packages.numpy ];

  cmakeFlags = [
    "-DCMAKE_POLICY_VERSION_MINIMUM=3.5"
    "-DHTRAAPI_INCLUDE_DIR=${harogic-htra-sdk}/include"
    "-DHTRAAPI_LIBRARY=${harogic-htra-sdk}/lib/libhtraapi.so"
  ];

  meta = {
    description = "GNU Radio OOT source block for Harogic HTRA spectrum analyzers";
    homepage = "https://github.com/HAROGIC-Technologies/gr-htra";
    license = lib.licenses.gpl3Plus;
    # HTRA SDK host libraries plus the upstream ARM LTO segfault limit this to
    # x86_64 Linux.
    platforms = [ "x86_64-linux" ];
  };
}
