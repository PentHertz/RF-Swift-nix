# gr-hydrasdr: dedicated GNU Radio OOT source block for HydraSDR
# (PentHertz/gr-hydrasdr). This is the standalone `hydrasdr` block set — distinct
# from the HydraSDR backend inside gr-osmosdr — matching RF-Swift-images'
# grhydrasdr_grmod_install. It links libhydrasdr and ships its own
# FindLibHYDRASDR.cmake (pkg-config + header/lib search), which resolves the Nix
# libhydrasdr via its libhydrasdr.pc. Available on Darwin too: libhydrasdr and
# GNU Radio both build there, and this module is what puts HydraSDR into
# gnuradio-companion on macOS.
{ lib, stdenv, fetchFromGitHub, gnuradioPackages, cmake, pkg-config
, boost, spdlog, gmp, mpir, volk, libhydrasdr, python3Packages }:

gnuradioPackages.mkDerivation {
  pname = "gr-hydrasdr";
  version = "unstable-penthertz";

  src = fetchFromGitHub {
    owner = "PentHertz";
    repo = "gr-hydrasdr";
    rev = "e3222206a23005d4f87428da11341090963e49b6";
    hash = "sha256-oVnM9dA9eraGXOblfBmoD/wni2MIqzLT0epdx4P48A4=";
  };

  # Defensive: the published repo has historically carried a committed build/
  # dir whose CMakeCache.txt is pinned to a foreign absolute path, which makes
  # cmake refuse to configure (the same reason RF-Swift-images wipes it). nix
  # configures in its own build dir, so drop any in-tree one to be safe.
  postPatch = ''
    rm -rf build
  '';

  nativeBuildInputs = [ cmake pkg-config python3Packages.pybind11 ];
  # gnuradio's block.h includes the bignum C++ header of whatever nixpkgs built
  # GNU Radio against: <gmpxx.h> (gmp) on Linux, <mpirxx.h> (mpir) on Darwin.
  buildInputs = [ boost spdlog volk libhydrasdr python3Packages.numpy ]
    ++ [ (if stdenv.hostPlatform.isDarwin then mpir else gmp) ];
  cmakeFlags = [ "-DCMAKE_POLICY_VERSION_MINIMUM=3.5" ];

  meta = {
    description = "GNU Radio OOT source block for HydraSDR (PentHertz fork)";
    homepage = "https://github.com/PentHertz/gr-hydrasdr";
    license = lib.licenses.gpl3Plus;
    # libhydrasdr builds on macOS, so this module does too; keep it unix-wide so
    # gnuradio-rfswift(-light) can embed it on Darwin as well as Linux.
    platforms = lib.platforms.unix;
  };
}
