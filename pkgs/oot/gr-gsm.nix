# gr-gsm: GSM receiver/analysis OOT for GNU Radio. Upstream is 3.8-era; use the
# bkerler maint-3.10 fork for GNU Radio 3.10.
{ lib, fetchFromGitHub, gnuradioPackages, cmake, pkg-config, perl
, boost, spdlog, gmp, log4cpp, volk, fftwFloat, libosmocore, python3Packages
, gr-osmosdr-penthertz }:

gnuradioPackages.mkDerivation {
  pname = "gr-gsm";
  version = "maint-3.10";

  src = fetchFromGitHub {
    owner = "velichkov";
    repo = "gr-gsm";
    rev = "maint-3.10-fixes";
    hash = "sha256-9Mm6d6hMWylFbGXKBez5KZOGG/1KaOgk4EBZvgeEVHI=";
  };

  nativeBuildInputs = [ cmake pkg-config perl python3Packages.pybind11 python3Packages.mako python3Packages.six python3Packages.pyyaml ];
  buildInputs = [ boost spdlog gmp log4cpp volk fftwFloat libosmocore gr-osmosdr-penthertz python3Packages.numpy ];
  cmakeFlags = [
    "-DCMAKE_POLICY_VERSION_MINIMUM=3.5"
    # grcc can't resolve OOT blocks inside the sandbox (the makefile scrubs the
    # env before invoking it), so skip precompiling the livemon .grc GUI apps.
    # The blocks and all grgsm_* Python CLI tools still build, and the flowgraphs
    # remain openable in gnuradio-companion at runtime.
    "-DENABLE_GRCC=OFF"
  ];

  # Boost 1.87+ removed the long-deprecated io_service (use io_context) and the
  # resolver::query class (use the host/service resolve() overload). The 3.10
  # fork still uses both, so migrate the source.
  postPatch = ''
    find . \( -name '*.cc' -o -name '*.h' -o -name '*.cpp' \) \
      -exec sed -i \
        -e 's/boost::asio::io_service/boost::asio::io_context/g' \
        -e 's/io_service/io_context/g' {} +
    perl -0777 -i -pe 's/udp::resolver::query\s+rx_query\([^;]*;\s*udp::resolver::query\s+tx_query\([^;]*;\s*d_udp_endpoint_rx\s*=\s*\*resolver\.resolve\(rx_query\);\s*d_udp_endpoint_tx\s*=\s*\*resolver\.resolve\(tx_query\);/d_udp_endpoint_rx = *resolver.resolve(udp::v4(), bind_addr, src_port).begin();\n  d_udp_endpoint_tx = *resolver.resolve(udp::v4(), remote_addr, dst_port).begin();/s' lib/misc_utils/udp_socket.cc
    # grcc compiles the livemon .grc apps at build time and needs both osmosdr's
    # source block and gr-gsm's own blocks on the block path. Export here (at the
    # source root) so it persists into the build phase.
    export GRC_BLOCKS_PATH="${gr-osmosdr-penthertz}/share/gnuradio/grc/blocks:$PWD/grc''${GRC_BLOCKS_PATH:+:$GRC_BLOCKS_PATH}"
  '';

  meta = {
    description = "GNU Radio blocks and apps to receive and analyze GSM (bkerler 3.10 fork)";
    homepage = "https://github.com/bkerler/gr-gsm";
    license = lib.licenses.gpl3Plus;
    platforms = lib.platforms.linux;
    mainProgram = "grgsm_livemon";
  };
}
