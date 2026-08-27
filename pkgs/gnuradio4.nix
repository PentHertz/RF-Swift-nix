# Experimental GNU Radio 4, installed alongside GNU Radio 3.10. This mirrors
# RF-Swift-images' dedicated sdr_gnuradio4 add-on without changing the default
# SDR environments. All FetchContent inputs are supplied explicitly so the
# build remains network-free and reproducible in the Nix sandbox.
{ lib
, stdenv
, fetchFromGitHub
, cmake
, ninja
, pkg-config
, git
, alsa-lib
, libpulseaudio
, soapysdr
}:

let
  boostUtSrc = fetchFromGitHub {
    owner = "boost-ext";
    repo = "ut";
    rev = "53e17f25119598c6458d30351b260193096ba67e";
    hash = "sha256-Xfbq/7i7NREWG+Z971l7QBqHYk/o7JhYePYq3uvLbL0=";
  };
  virSimdSrc = fetchFromGitHub {
    owner = "mattkretz";
    repo = "vir-simd";
    rev = "v0.4.4";
    hash = "sha256-6wEKI95CO0caTtGR5L5L2rKER4K4/clTCFkOK0o2iAQ=";
  };
  httplibSrc = fetchFromGitHub {
    owner = "yhirose";
    repo = "cpp-httplib";
    rev = "v0.18.1";
    hash = "sha256-NLSflHzxXby+SpLFg32BfRafey48DZ0XULQeyHQJHP4=";
  };
  libsoundioSrc = fetchFromGitHub {
    owner = "andrewrk";
    repo = "libsoundio";
    rev = "49a1f78b50eb0f5a49d096786a95a93874a2592a";
    hash = "sha256-ZVwspmW86szE0HXZyHTu3dBXJahVJ9Ft2JuTeDcUf44=";
  };
in
stdenv.mkDerivation rec {
  pname = "gnuradio4";
  version = "4.0.0-RC2";

  src = fetchFromGitHub {
    owner = "gnuradio";
    repo = "gnuradio4";
    rev = "c946b140996efae16486f2118e0faca6f8e52c14";
    hash = "sha256-e5zxIhQtWdVq9KhRMVhbFlfHDRE+ndUxyDlez4OgNV0=";
  };

  nativeBuildInputs = [ cmake ninja pkg-config git ];
  buildInputs = [ alsa-lib libpulseaudio soapysdr ];

  # GR4 generates very large, template-heavy translation units. Even three
  # concurrent GCC processes exceed the memory available on typical CI runners
  # (and on the local verifier), so keep this opt-in package deliberately
  # serial. Failed Nix builds do not retain Ninja's partial object cache.
  enableParallelBuilding = false;
  buildFlags = [ "-j1" ];

  postPatch = ''
    # Nix's CMake hook supplies absolute GNUInstallDirs. Upstream's template
    # prepends prefix a second time, producing `''${prefix}//nix/store/...`.
    substituteInPlace cmake/gnuradio4.pc.in \
      --replace-fail 'libdir=''${exec_prefix}/@CMAKE_INSTALL_LIBDIR@' \
                     'libdir=@CMAKE_INSTALL_FULL_LIBDIR@' \
      --replace-fail 'includedir=''${prefix}/@CMAKE_INSTALL_INCLUDEDIR@' \
                     'includedir=@CMAKE_INSTALL_FULL_INCLUDEDIR@'
  '';

  cmakeFlags = [
    # The RC2 registry generator instantiates a combinatorial converter matrix;
    # one generated unit alone exceeds 10 GiB with GCC 15. Core GR4 and its
    # block libraries do not require the optional runtime plugin registry.
    "-DGR_ENABLE_BLOCK_REGISTRY=OFF"
    "-DGR_ENABLE_HTTP=OFF"
    "-DENABLE_EXAMPLES=OFF"
    "-DENABLE_TESTING=OFF"
    "-DENABLE_TBB=OFF"
    "-DUSE_CCACHE=OFF"
    "-DWARNINGS_AS_ERRORS=OFF"
    "-DFETCHCONTENT_FULLY_DISCONNECTED=ON"
    "-DFETCHCONTENT_SOURCE_DIR_UT=${boostUtSrc}"
    "-DFETCHCONTENT_SOURCE_DIR_VIR-SIMD=${virSimdSrc}"
    "-DFETCHCONTENT_SOURCE_DIR_CPP-HTTPLIB=${httplibSrc}"
    "-DFETCHCONTENT_SOURCE_DIR_LIBSOUNDIO=${libsoundioSrc}"
  ];

  # Upstream's libsoundio FetchContent declaration tries to apply a compatibility
  # patch. A Nix store source is immutable; patch a writable copy and point CMake
  # at that copy instead.
  preConfigure = ''
    cp -r ${libsoundioSrc} .libsoundio-source
    chmod -R u+w .libsoundio-source
    git -C .libsoundio-source apply --ignore-space-change --ignore-whitespace \
      "$PWD/patches/libsoundio-cmake4.diff"
    cmakeFlagsArray+=("-DFETCHCONTENT_SOURCE_DIR_LIBSOUNDIO=$PWD/.libsoundio-source")
  '';

  meta = {
    description = "Experimental GNU Radio 4 runtime and block library";
    homepage = "https://github.com/gnuradio/gnuradio4";
    license = with lib.licenses; [ lgpl3Plus mit ];
    platforms = lib.platforms.linux;
  };
}
