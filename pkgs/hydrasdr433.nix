# hydrasdr_433: dedicated HydraSDR fork of rtl_433 (native CF32/float32 IQ),
# matching RF-Swift-images' hydrasdr433_soft_install. The upstream CMake would
# FetchContent libhydrasdr from GitHub when it is not found locally — impossible
# in the Nix sandbox, and it triggers whenever ENABLE_HYDRASDR=ON regardless of
# HYDRASDR_FETCH_FROM_GIT. Its FindHydraSDR.cmake also probes the pkg-config
# module `hydrasdr`, but ours is named `libhydrasdr`, so autodetection misses.
# We therefore pre-seed the find_package result cache variables to point straight
# at the Nix libhydrasdr (header dir + dylib); find_package then reports FOUND and
# the network-fetch branch is never entered.
{ lib, stdenv, fetchFromGitHub, cmake, pkg-config, python3, libhydrasdr, libusb1, openssl }:

stdenv.mkDerivation {
  pname = "hydrasdr433";
  version = "unstable-hydrasdr";

  src = fetchFromGitHub {
    owner = "hydrasdr";
    repo = "hydrasdr_433";
    rev = "c02ea392812a49525c08ac067d68306bae65f30e";
    hash = "sha256-l+buzYlCa177gzNKteMV4+6x68rD+NsPNmK5bkwn8Ms=";
  };

  # python3 is needed at build time: src/CMakeLists.txt generates the embedded
  # web-UI header (webui_assets.h, via tools/gen_webui.py) only when a Python
  # interpreter is found; without it http_server.c fails to find the header.
  # The install step references a man/ dir in the source tree that the repo does
  # not ship (RF-Swift-images' installer creates it by hand before `make install`);
  # create it so `file INSTALL .../man` succeeds.
  postPatch = ''
    mkdir -p man
  '';

  nativeBuildInputs = [ cmake pkg-config python3 ];
  buildInputs = [ libhydrasdr libusb1 openssl ];

  # Force the local (Nix) libhydrasdr and forbid the network FetchContent branch.
  # hydrasdr.h lives in include/libhydrasdr/; the source #includes <hydrasdr.h>,
  # so that subdir is the include root we hand find_package.
  cmakeFlags = [
    "-DENABLE_HYDRASDR=ON"
    "-DHYDRASDR_FETCH_FROM_GIT=OFF"
    "-DHydraSDR_INCLUDE_DIR=${libhydrasdr}/include/libhydrasdr"
    "-DHydraSDR_LIBRARY=${libhydrasdr}/lib/libhydrasdr${stdenv.hostPlatform.extensions.sharedLibrary}"
    "-DCMAKE_POLICY_VERSION_MINIMUM=3.5"
  ];

  meta = {
    description = "HydraSDR fork of rtl_433 with native CF32 IQ support";
    homepage = "https://github.com/hydrasdr/hydrasdr_433";
    license = lib.licenses.gpl2Plus;
    mainProgram = "hydrasdr_433";
    platforms = lib.platforms.unix;
  };
}
