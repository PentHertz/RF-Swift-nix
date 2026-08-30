# gr-bladeRF: Nuand's dedicated GNU Radio OOT source/sink blocks for the bladeRF
# (distinct from the bladeRF backend inside gr-osmosdr), matching
# RF-Swift-images' grbladerf_grmod_install. Links libbladeRF via the module's
# own FindLibbladeRF.cmake. gnuradio-iqbalance is an optional (non-REQUIRED)
# find_package; when absent the module simply builds without IQ-balance support.
# It reuses gr-osmosdr's public headers (osmosdr/ranges.h, osmosdr/api.h) and
# links its library, so gr-osmosdr(-penthertz) is a hard build dependency.
{ lib, stdenv, fetchFromGitHub, gnuradioPackages, cmake, pkg-config
, boost, spdlog, gmp, mpir, volk, libbladeRF, gr-osmosdr-penthertz, python3Packages }:

gnuradioPackages.mkDerivation {
  pname = "gr-bladeRF";
  version = "unstable-nuand";

  src = fetchFromGitHub {
    owner = "Nuand";
    repo = "gr-bladeRF";
    rev = "dc38158aee335a3b02d8da5d301febc9fa05b632";
    hash = "sha256-aB4CcieuozfATpWKYlH09zuyL+XlnixAkXQNZnSxHx8=";
  };

  postPatch = ''
    rm -rf build
  '';

  # The GRC block YAMLs are generated at build time by grc/gen_bladerf_blocks.py,
  # which renders its templates with Mako - so Mako must be present to configure.
  nativeBuildInputs = [ cmake pkg-config python3Packages.pybind11 python3Packages.mako ];
  # gnuradio's block.h includes <gmpxx.h> on Linux and <mpirxx.h> on Darwin.
  buildInputs = [ boost spdlog volk libbladeRF gr-osmosdr-penthertz python3Packages.numpy ]
    ++ [ (if stdenv.hostPlatform.isDarwin then mpir else gmp) ];
  cmakeFlags = [ "-DCMAKE_POLICY_VERSION_MINIMUM=3.5" ];

  meta = {
    description = "GNU Radio OOT source/sink blocks for Nuand bladeRF";
    homepage = "https://github.com/Nuand/gr-bladeRF";
    license = lib.licenses.gpl3Plus;
    # libbladeRF builds on macOS, so this module does too.
    platforms = lib.platforms.unix;
  };
}
