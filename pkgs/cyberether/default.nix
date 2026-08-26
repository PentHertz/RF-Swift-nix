# CyberEther (luigifcruz) - heterogeneous SDR visualisation with a Vulkan/WebGPU
# renderer. Its meson build vendors ~40 dependencies as subproject wraps and
# downloads them (plus ~20 Natural Earth GeoJSON files) at build time, which the
# offline Nix sandbox forbids. We vendor every wrap SOURCE into meson's
# packagecache (the sha256s are embedded in the .wrap files) and pre-fetch the
# geodata, then build with --wrap-mode=nodownload. The heaviest optional
# features (remote GStreamer streaming, ONNX inference) are disabled so their
# giant subprojects (gstreamer-full, glib, onnxruntime) never build; openssl is
# taken from nixpkgs rather than compiled from source.
{ lib
, stdenv
, fetchFromGitHub
, fetchurl
, runCommandLocal
, meson
, ninja
, pkg-config
, git
, python3
, glslang
, spirv-cross
, vulkan-headers
, vulkan-loader
, openssl
, xorg
, xorgproto
, libxcb
, wayland
, wayland-protocols
, wayland-scanner
, libxkbcommon
, libGL
, udev
, glfw
, soapysdr
}:

let
  # --- Vendored meson subproject sources (name/url/sha256 from the .wrap files).
  wrapSrcs = [
    { name = "Catch2-3.4.0.tar.gz"; sha256 = "122928b814b75717316c71af69bd2b43387643ba076a6ec16e7882bfb2dfacbb"; url = "https://github.com/catchorg/Catch2/archive/v3.4.0.tar.gz"; }
    { name = "cpp-httplib-0.40.0.tar.gz"; sha256 = "b52ecaebf0f94086c8b3305650412359d920c5267f6d9ce87f883198783af678"; url = "https://github.com/yhirose/cpp-httplib/archive/refs/tags/v0.40.0.tar.gz"; }
    { name = "fmt-11.2.0.tar.gz"; sha256 = "bc23066d87ab3168f27cef3e97d545fa63314f5c79df5ea444d41d56f962c6af"; url = "https://github.com/fmtlib/fmt/archive/11.2.0.tar.gz"; }
    { name = "glfw-3.4.tar.gz"; sha256 = "c038d34200234d071fae9345bc455e4a8f2f544ab60150765d7704e08f3dac01"; url = "https://github.com/glfw/glfw/archive/refs/tags/3.4.tar.gz"; }
    { name = "glib-2.88.1.tar.xz"; sha256 = "51ab804c56f6eab3e5045c774d1290ac5e4c923d4f9a3d8e33123bee45c1840e"; url = "https://download.gnome.org/sources/glib/2.88/glib-2.88.1.tar.xz"; }
    { name = "glm-1.0.0.tar.gz"; sha256 = "e51f6c89ff33b7cfb19daafb215f293d106cd900f8d681b9b1295312ccadbd23"; url = "https://github.com/g-truc/glm/archive/refs/tags/1.0.0.tar.gz"; }
    { name = "gstreamer-1.28.2.tar.gz"; sha256 = "c221bcac5c954d8ac7a02d3ea34d5466058f073c43d48b7b317a7b0a78595ec3"; url = "https://gitlab.freedesktop.org/gstreamer/gstreamer/-/archive/1.28.2/gstreamer-1.28.2.tar.gz"; }
    { name = "airspyone_host-1.0.10.tar.gz"; sha256 = "fcca23911c9a9da71cebeffeba708c59d1d6401eec6eb2dd73cae35b8ea3c613"; url = "https://github.com/airspy/airspyone_host/archive/refs/tags/v1.0.10.tar.gz"; }
    { name = "libffi-3.5.2.tar.gz"; sha256 = "f3a3082a23b37c293a4fcd1053147b371f2ff91fa7ea1b2a52e335676bac82dc"; url = "https://github.com/libffi/libffi/releases/download/v3.5.2/libffi-3.5.2.tar.gz"; }
    { name = "libgudev-237.tar.bz2"; sha256 = "1cec460f8afaa0e613f92202699b31b5560843a4a86e019ebb1ef437675b74d8"; url = "https://gitlab.gnome.org/GNOME/libgudev/-/archive/237/libgudev-237.tar.bz2"; }
    { name = "hackrf-2026.01.3.tar.gz"; sha256 = "48238f3a21189fa8cbe67838584cc045b9e5433767db8c9c30c1da02a1489f2c"; url = "https://github.com/greatscottgadgets/hackrf/archive/refs/tags/v2026.01.3.tar.gz"; }
    { name = "librtlsdr-1261fbb285297da08f4620b18871b6d6d9ec2a7b.zip"; sha256 = "79925da4e274b87a98e5364459e0e3faf346bd56dfcb7d38fa089e5cc6785797"; url = "https://github.com/steve-m/librtlsdr/archive/1261fbb285297da08f4620b18871b6d6d9ec2a7b.zip"; }
    { name = "libsrtp-2.7.0.tar.gz"; sha256 = "54facb1727a557c2a76b91194dcb2d0a453aaf8e2d0cbbf1e3c2848c323e28ad"; url = "https://github.com/cisco/libsrtp/archive/refs/tags/v2.7.0.tar.gz"; }
    { name = "libusb-1.0.26.tar.bz2"; sha256 = "12ce7a61fc9854d1d2a1ffe095f7b5fac19ddba095c259e6067a46500381b5a5"; url = "https://github.com/libusb/libusb/releases/download/v1.0.26/libusb-1.0.26.tar.bz2"; }
    { name = "LimeSuite-23.11.0.tar.gz"; sha256 = "fd8a448b92bc5ee4012f0ba58785f3c7e0a4d342b24e26275318802dfe00eb33"; url = "https://github.com/myriadrf/LimeSuite/archive/refs/tags/v23.11.0.tar.gz"; }
    { name = "wgpu-22.1.0.tar.gz"; sha256 = "7caa75f945d3d8cecac35d6de1e1a5cb112c2b38f80c6034d47971dae940eceb"; url = "https://github.com/gfx-rs/wgpu/archive/refs/tags/v22.1.0.tar.gz"; }
    { name = "nanobench-4.3.11.tar.gz"; sha256 = "53a5a913fa695c23546661bf2cd22b299e10a3e994d9ed97daf89b5cada0da70"; url = "https://github.com/martinus/nanobench/archive/refs/tags/v4.3.11.tar.gz"; }
    { name = "nanobind-2.12.0.tar.gz"; sha256 = "01f1f0cd0398743c18f33d07ae36ad410bd7f4a1e90683b508504de897d6e629"; url = "https://github.com/wjakob/nanobind/archive/refs/tags/v2.12.0.tar.gz"; }
    { name = "nlohmann_json-3.12.0.zip"; sha256 = "b8cb0ef2dd7f57f18933997c9934bb1fa962594f701cd5a8d3c2c80541559372"; url = "https://github.com/nlohmann/json/releases/download/v3.12.0/include.zip"; }
    { name = "openssl-3.0.8.tar.gz"; sha256 = "6c13d2bf38fdf31eac3ce2a347073673f5d63263398f1f69d0df4a41253e4b3e"; url = "https://www.openssl.org/source/openssl-3.0.8.tar.gz"; }
    { name = "pcre2-10.47.tar.bz2"; sha256 = "47fe8c99461250d42f89e6e8fdaeba9da057855d06eb7fc08d9ca03fd08d7bc7"; url = "https://github.com/PCRE2Project/pcre2/releases/download/pcre2-10.47/pcre2-10.47.tar.bz2"; }
    { name = "pthreads4w-code-v3.0.0.zip"; sha256 = "b81136effb7185c77601fe2e0e6ac19bd996912e4814cebdd3010b0fac9e259b"; url = "https://downloads.sourceforge.net/project/pthreads4w/pthreads4w-code-v3.0.0.zip"; }
    { name = "libqrencode-4.1.1.tar.gz"; sha256 = "5385bc1b8c2f20f3b91d258bf8ccc8cf62023935df2d2676b5b67049f31a049c"; url = "https://github.com/fukuchi/libqrencode/archive/refs/tags/v4.1.1.tar.gz"; }
    { name = "rapidyaml-0.11.1-src.tgz"; sha256 = "9d9938269adc25e9a9b84650338b87d130cf469d82685fffc028c325279619c1"; url = "https://github.com/biojppm/rapidyaml/releases/download/v0.11.1/rapidyaml-0.11.1-src.tgz"; }
    { name = "robin-map-1.4.0.tar.gz"; sha256 = "7930dbf9634acfc02686d87f615c0f4f33135948130b8922331c16d90a03250c"; url = "https://github.com/Tessil/robin-map/archive/refs/tags/v1.4.0.tar.gz"; }
    { name = "SoapyAirspy-soapy-airspy-0.2.0.tar.gz"; sha256 = "4279ab4278fab699ef8325f3f921b2307496130a56028d33022be10916b6ccff"; url = "https://github.com/pothosware/SoapyAirspy/archive/refs/tags/soapy-airspy-0.2.0.tar.gz"; }
    { name = "SoapyHackRF-soapy-hackrf-0.3.4.tar.gz"; sha256 = "c7a1b8aee7af9d9e11e42aa436eae8508f19775cdc8bc52e565a5d7f2e2e43ed"; url = "https://github.com/pothosware/SoapyHackRF/archive/refs/tags/soapy-hackrf-0.3.4.tar.gz"; }
    { name = "SoapyRemote-soapy-remote-0.5.2.tar.gz"; sha256 = "66a372d85c984e7279b4fdc0a7f5b0d7ba340e390bc4b8bd626a6523cd3c3c76"; url = "https://github.com/pothosware/SoapyRemote/archive/refs/tags/soapy-remote-0.5.2.tar.gz"; }
    { name = "SoapyRTLSDR-soapy-rtl-sdr-0.3.3.tar.gz"; sha256 = "757c3c3bd17c5a12c7168db2f2f0fd274457e65f35e23c5ec9aec34e3ef54ece"; url = "https://github.com/pothosware/SoapyRTLSDR/archive/refs/tags/soapy-rtl-sdr-0.3.3.tar.gz"; }
    { name = "SoapySDR-soapy-sdr-0.8.1.tar.gz"; sha256 = "a508083875ed75d1090c24f88abef9895ad65f0f1b54e96d74094478f0c400e6"; url = "https://github.com/pothosware/SoapySDR/archive/refs/tags/soapy-sdr-0.8.1.tar.gz"; }
    { name = "tree-sitter-markdown-0.5.3.tar.gz"; sha256 = "22e40c51810e64c6bf073f0147f3abc167473206789e6dcbed4ba198ff3ca119"; url = "https://github.com/tree-sitter-grammars/tree-sitter-markdown/releases/download/v0.5.3/tree-sitter-markdown.tar.gz"; }
    { name = "tree-sitter-python-0.25.0.tar.gz"; sha256 = "7bce887eb2f33e94bf74a69645cf5138d4096720e54fd3269a6124c06b93c584"; url = "https://github.com/tree-sitter/tree-sitter-python/releases/download/v0.25.0/tree-sitter-python.tar.gz"; }
    { name = "tree-sitter-0.26.3.tar.gz"; sha256 = "7f4a7cf0a2cd217444063fe2a4d800bc9d21ed609badc2ac20c0841d67166550"; url = "https://github.com/tree-sitter/tree-sitter/archive/refs/tags/v0.26.3.tar.gz"; }
    { name = "velopack_libc_1.2.0.zip"; sha256 = "547262ed7a1ab1ff62f580aa53851ede2f1a451ac61b8974eb7bc01117488835"; url = "https://github.com/velopack/velopack/releases/download/1.2.0/velopack_libc_1.2.0.zip"; }
    { name = "zlib-1.3.2.tar.xz"; sha256 = "d7a0654783a4da529d1bb793b7ad9c3318020af77667bcae35f95d0e42a792f3"; url = "https://zlib.net/zlib-1.3.2.tar.xz"; }

    # WrapDB patch overlays (the meson build files) - also needed in packagecache.
    { name = "glfw_3.4-2_patch.zip"; sha256 = "c722d2983acaea2b2ed68570cc7958a10485d8362547cff67713ed4859aa2bc8"; url = "https://github.com/mesonbuild/wrapdb/releases/download/glfw_3.4-2/glfw_3.4-2_patch.zip"; }
    { name = "glm_1.0.0-1_patch.zip"; sha256 = "fbb97f9cca2bda1f9dea6efddf3742105613b8e68d089b9a01307159bd2f37a1"; url = "https://github.com/mesonbuild/wrapdb/releases/download/glm_1.0.0-1/glm_1.0.0-1_patch.zip"; }
    { name = "libffi_3.5.2-2_patch.zip"; sha256 = "74ed624f74cd860be3bdf6d473b70ab88707bdf2f940191fbcb577e2a49a9710"; url = "https://github.com/mesonbuild/wrapdb/releases/download/libffi_3.5.2-2/libffi_3.5.2-2_patch.zip"; }
    { name = "libusb_1.0.26-5_patch.zip"; sha256 = "6b107bcc552a531099c19181b327b8d62c2c73bdc4d488f85449d140d3e7eb9b"; url = "https://github.com/mesonbuild/wrapdb/releases/download/libusb_1.0.26-5/libusb_1.0.26-5_patch.zip"; }
    { name = "nanobind_2.12.0-1_patch.zip"; sha256 = "4b8158bdb359218bcfb7a5b4459fbfa5919171d9ea2400de3a84cf9ab7c7308b"; url = "https://github.com/mesonbuild/wrapdb/releases/download/nanobind_2.12.0-1/nanobind_2.12.0-1_patch.zip"; }
    { name = "openssl_3.0.8-3_patch.zip"; sha256 = "300da189e106942347d61a4a4295aa2edbcf06184f8d13b4cee0bed9fb936963"; url = "https://github.com/mesonbuild/wrapdb/releases/download/openssl_3.0.8-3/openssl_3.0.8-3_patch.zip"; }
    { name = "pcre2_10.47-3_patch.zip"; sha256 = "42df135f63e216141ffcc30e3e7c8ae6bdea21f7638828cbab5f7ad484fa9044"; url = "https://github.com/mesonbuild/wrapdb/releases/download/pcre2_10.47-3/pcre2_10.47-3_patch.zip"; }
    { name = "qrencode_4.1.1-3_patch.zip"; sha256 = "2c95bbbe32122b7dacd325c878f21039e1e77c3e12e8f2f74c4d7f07cc99de46"; url = "https://github.com/mesonbuild/wrapdb/releases/download/qrencode_4.1.1-3/qrencode_4.1.1-3_patch.zip"; }
    { name = "robin-map_1.4.0-1_patch.zip"; sha256 = "feb14b6752b7d439fb2f3ee968e595a9a3de00ef8cb029488af2ceb4f504b95d"; url = "https://github.com/mesonbuild/wrapdb/releases/download/robin-map_1.4.0-1/robin-map_1.4.0-1_patch.zip"; }
    { name = "tree-sitter_0.26.3-1_patch.zip"; sha256 = "268ff355375227f95b816426c8e05f162b7fb8334f9eaa23ce3dcf121e0c9f0a"; url = "https://github.com/mesonbuild/wrapdb/releases/download/tree-sitter_0.26.3-1/tree-sitter_0.26.3-1_patch.zip"; }
    { name = "zlib_1.3.2-1_patch.zip"; sha256 = "5ae7a2e92f823df118cfb8c1b23d94e3117864392b3446581d669049b2fba6dd"; url = "https://github.com/mesonbuild/wrapdb/releases/download/zlib_1.3.2-1/zlib_1.3.2-1_patch.zip"; }
  ];

  # Only the wraps actually built need to be in the packagecache. With remote and
  # inference disabled and soapy/glfw/openssl routed to nixpkgs, the giant ones
  # (gstreamer, glib, wgpu/naga, openssl, the whole SoapySDR stack, limesuite,
  # ...) are never built - dropping them keeps the packagecache small enough for
  # the sandbox disk quota.
  builtNames = [
    "Catch2-3.4.0.tar.gz" "cpp-httplib-0.40.0.tar.gz" "fmt-11.2.0.tar.gz"
    "glm-1.0.0.tar.gz" "nanobench-4.3.11.tar.gz" "nlohmann_json-3.12.0.zip"
    "libqrencode-4.1.1.tar.gz" "rapidyaml-0.11.1-src.tgz" "robin-map-1.4.0.tar.gz"
    "tree-sitter-markdown-0.5.3.tar.gz" "tree-sitter-python-0.25.0.tar.gz"
    "tree-sitter-0.26.3.tar.gz" "velopack_libc_1.2.0.zip" "zlib-1.3.2.tar.xz"
    # WrapDB patches for the above:
    "glm_1.0.0-1_patch.zip" "qrencode_4.1.1-3_patch.zip" "robin-map_1.4.0-1_patch.zip"
    "tree-sitter_0.26.3-1_patch.zip" "zlib_1.3.2-1_patch.zip"
  ];
  builtSrcs = builtins.filter (s: builtins.elem s.name builtNames) wrapSrcs;

  packagecache = runCommandLocal "cyberether-packagecache" { } (''
    mkdir -p $out
  '' + lib.concatMapStrings
    (s: "cp ${fetchurl { inherit (s) url sha256; name = s.name; }} $out/${s.name}\n")
    builtSrcs);

  # The two git-based wraps (both required by their loaders). vpx/libusb-browser
  # are only pulled by the disabled remote/GStreamer path, so they are omitted.
  stbSrc = fetchFromGitHub {
    owner = "nothings";
    repo = "stb";
    rev = "f58f558c120e9b32c217290b80bad1a0729fbb2c";
    hash = "sha256-FGe6ffCqscwz+kgZcIwWsGaEM/9VnJp+d7bHUTl39DU=";
  };
  libmodesSrc = fetchFromGitHub {
    owner = "watson";
    repo = "libmodes";
    rev = "e82c6faedd21ced7fd1c2808c0d9e9ffbb8c0ed6";
    hash = "sha256-brU6IYHcCJbArYf4DMyj3DfKp2unsjZq+IaM5M1pK1I=";
  };

  # --- Natural Earth geodata (parser.py downloads these at build time). --------
  geodataFiles = {
    "ne_10m_admin_0_boundary_lines_land.geojson" = "sha256-dNnBYinAlf3mWUOpkZ4zdoLwRLzrzLEgdk847fO3D0o=";
    "ne_10m_admin_1_states_provinces_lines.geojson" = "sha256-Gh8wzKr0zJxL3jQmbwuMu5VdOkzyVLdWkSJV8ux8dbY=";
    "ne_10m_bathymetry_A_10000.geojson" = "sha256-iCHW6AA/CnSm0dGDed7YjuY4s+RX8rq51BJKzDzRVJI=";
    "ne_10m_bathymetry_B_9000.geojson" = "sha256-/w6Ws8O6qGP4JQP+NDS9YE/+b70nyr7n9x3RgH/O5aA=";
    "ne_10m_bathymetry_C_8000.geojson" = "sha256-jzaUA3vn9Uv0n8b6PyBF8yXqzbaciCi41IKzA7V+NYo=";
    "ne_10m_bathymetry_D_7000.geojson" = "sha256-Getd1Z031sbamw0EJSdpxicIqtahV48W1qe4sw/QXFY=";
    "ne_10m_bathymetry_E_6000.geojson" = "sha256-dfw0r91bxUo+vgk/wKaAr3DPJV8bPn6ArXXnlfXMTI0=";
    "ne_10m_bathymetry_F_5000.geojson" = "sha256-57Zj8/YUTB0juCBWGP0e61JWxLA3hajtAJF4IJ1ounI=";
    "ne_10m_bathymetry_G_4000.geojson" = "sha256-rYdua2toZJSg6J8AlogKZ1Wu53rz1zh5S7vJIhavzz0=";
    "ne_10m_bathymetry_H_3000.geojson" = "sha256-KP2os037hhX5ZEv/PlbBhFAeIdzLgH1ChDLlbY2sDPU=";
    "ne_10m_bathymetry_I_2000.geojson" = "sha256-ze3HRs4G4aBRy4kF6PB4VSJcy9NWDOOmZgdlH8aVPOI=";
    "ne_10m_bathymetry_J_1000.geojson" = "sha256-+jAhmQHdTeNLn1sg9BvHwFX5/J1YzxV60meclSOc02Y=";
    "ne_10m_bathymetry_K_200.geojson" = "sha256-XGwYLahggVPqLc4i37MsmH5TkOC9ShIiZhQ7oYGntjY=";
    "ne_10m_bathymetry_L_0.geojson" = "sha256-5e/Z9H1WeRyUnebQmdapzdTRrsqY1d1jlHwLRLmWYAg=";
    "ne_10m_coastline.geojson" = "sha256-b3WuDg3hV7FJRuIlXrH1SG2aE4GQMuJtRhCFLSlniPY=";
    "ne_10m_lakes.geojson" = "sha256-LQNvU97exXgAHFwwwpWe59TuvBMGkA+kNnxJkp7I8tk=";
    "ne_10m_land.geojson" = "sha256-GskHlkCLxq1pEdaUSEhdPE2/IZA3AIA2igmXbhyfdBY=";
    "ne_10m_populated_places_simple.geojson" = "sha256-/T+oZ6Mgy9XFtrtbxVCv7sKTn7LO9ojlCABygqVaxC8=";
    "ne_10m_rivers_lake_centerlines.geojson" = "sha256-u4VKkA7L07QI30bV4W4+D5dLpVmT+di1wm6FUnPAkFo=";
    "ne_10m_urban_areas.geojson" = "sha256-UTb/2BapsowPKV5nl7TAPqpCG+gNeLkPVC20qTLdRJc=";
  };
  geodata = runCommandLocal "cyberether-geodata" { } (''
    mkdir -p $out
  '' + lib.concatStrings (lib.mapAttrsToList
    (fn: h: "cp ${fetchurl { url = "https://cdn.cyberether.org/geodata/${fn}"; hash = h; }} $out/${fn}\n")
    geodataFiles));

  # CyberEther requires meson >= 1.11.0; nixpkgs ships 1.10.2. Bump the source
  # and skip meson's own (very long) project test suite.
  mesonNew = meson.overrideAttrs (_: {
    version = "1.11.0";
    src = fetchFromGitHub {
      owner = "mesonbuild";
      repo = "meson";
      rev = "1.11.0";
      hash = "sha256-y2EC4uEtocMP0lWq7aegnPV+xzDG69+UBxKTSfGXf7w=";
    };
    doCheck = false;
    doInstallCheck = false;
  });

  # Python with the modules the geodata triangulation step imports at build time.
  pythonForBuild = python3.withPackages (ps: [ ps.numpy ps.mapbox-earcut ]);

in
stdenv.mkDerivation {
  pname = "cyberether";
  version = "1.9.1";

  src = fetchFromGitHub {
    owner = "luigifcruz";
    repo = "CyberEther";
    rev = "v1.9.1";
    hash = "sha256-pT9dbc6NNvUAvhuOr7WgorKBsNPfrz3Jv/3MCFs8cNo=";
  };

  nativeBuildInputs = [
    mesonNew ninja pkg-config git pythonForBuild glslang spirv-cross
    wayland-scanner
  ];
  buildInputs = [
    vulkan-headers vulkan-loader openssl libGL
    # glfw and the SoapySDR stack come from nixpkgs (routed away from the wraps).
    glfw soapysdr
    xorg.libX11 xorg.libXrandr xorg.libXinerama xorg.libXcursor xorg.libXi
    xorg.libXext libxcb xorgproto
    wayland wayland-protocols libxkbcommon
    udev
  ];

  postPatch = ''
    # Vendor every meson subproject source into the packagecache and pre-place
    # the geodata so parser.py finds it and skips its network download.
    # meson's packagecache needs real files (it rejects symlinks), so copy the
    # wrap tarballs; the geodata is only read by parser.py, so symlink it to save
    # the sandbox disk quota.
    mkdir -p subprojects/packagecache
    cp ${packagecache}/* subprojects/packagecache/
    ln -sf ${geodata}/*.geojson resources/geodata/

    # Vendor the git-based wraps offline: place the checkout and apply the wrap's
    # packagefiles overlay (+ libmodes' diff) so meson uses them directly.
    mkdir -p subprojects/stb subprojects/libmodes
    cp -rT ${stbSrc} subprojects/stb
    cp -rT ${libmodesSrc} subprojects/libmodes
    chmod -R u+w subprojects/stb subprojects/libmodes
    cp -f subprojects/packagefiles/stb/* subprojects/stb/
    cp -f subprojects/packagefiles/libmodes/meson.build subprojects/libmodes/
    patch -d subprojects/libmodes -p1 < subprojects/packagefiles/libmodes/mode-s-timeh.diff

    # Take openssl from nixpkgs rather than compiling it from source (it is only
    # pulled in for the disabled remote/GStreamer path). Rewrite the loader.
    cat > meson/loaders/openssl/meson.build <<'EOF'
    openssl_dep = dependency('openssl', required: false)
    libssl_dep = dependency('libssl', required: false)
    libcrypto_dep = dependency('libcrypto', required: false)
    deps = [openssl_dep, libssl_dep, libcrypto_dep]
    all_deps_found = not jst_is_browser
    foreach x_dep : deps
        all_deps_found = all_deps_found and x_dep.found()
    endforeach
    if all_deps_found
        cfg_lst.set('JETSTREAM_LOADER_OPENSSL_AVAILABLE', true)
        dep_lst += deps
    endif
    ldr_lst += {'OpenSSL': all_deps_found}
    EOF
    sed -i 's/^    //' meson/loaders/openssl/meson.build

    # Route the SoapySDR stack to nixpkgs instead of statically link-whole'ing
    # ~10 vendored subprojects (soapysdr + airspy/lime/rtlsdr/hackrf modules and
    # their device libs). CyberEther links SoapySDR core; the device modules are
    # loaded at runtime from SOAPY_SDR_PLUGIN_PATH (set by the wrapper).
    cat > meson/loaders/soapy/meson.build <<'EOF'
    soapysdr_dep = dependency('SoapySDR', required: false)
    deps = [soapysdr_dep]
    all_deps_found = true
    foreach x_dep : deps
        all_deps_found = all_deps_found and x_dep.found()
    endforeach
    if all_deps_found
        cfg_lst.set('JETSTREAM_LOADER_SOAPY_AVAILABLE', true)
        dep_lst += deps
    endif
    ldr_lst += {'SoapySDR': all_deps_found}
    EOF
    sed -i 's/^    //' meson/loaders/soapy/meson.build

    # Route glfw to nixpkgs too (avoids building it + the whole X11/Wayland stack
    # from the wrap).
    cat > meson/loaders/glfw/meson.build <<'EOF'
    glfw_dep = dependency('glfw3', required: false)
    deps = []
    if not jst_is_browser
        deps += [glfw_dep]
    endif
    all_deps_found = true
    foreach x_dep : deps
        all_deps_found = all_deps_found and x_dep.found()
    endforeach
    all_deps_found = all_deps_found or jst_is_browser
    if all_deps_found
        cfg_lst.set('JETSTREAM_LOADER_GLFW_AVAILABLE', true)
        dep_lst += deps
    endif
    ldr_lst += {'GLFW': all_deps_found}
    EOF
    sed -i 's/^    //' meson/loaders/glfw/meson.build

    # cpp-httplib 0.40's experimental split/compiled mode omits the exported
    # WebSocketClient definitions from the static library as consumed here,
    # leaving CyberEther's WebSocket module unresolved at the final link. Its
    # supported default is header-only, where those definitions remain inline.
    substituteInPlace meson/loaders/cpphttplib/meson.build \
      --replace-fail "'compile=true'" "'compile=false'"
  '';

  # The geodata step does `pymod.find_installation(py.full_path(), modules:
  # ['numpy','mapbox_earcut'])`; py.full_path() resolves through the withPackages
  # wrapper to the bare interpreter, which cannot see the modules. Put the env's
  # site-packages on PYTHONPATH so the bare python3 finds numpy + mapbox_earcut.
  preConfigure = ''
    export PYTHONPATH="${pythonForBuild}/${python3.sitePackages}''${PYTHONPATH:+:$PYTHONPATH}"
  '';

  # debugoptimized (-O2) rather than release (-O3): matches RF Swift's own x86_64
  # build and roughly halves the peak RAM cc1plus needs on the heavy header-only
  # (fmt) C++20 translation units, which -O3 + parallel jobs can OOM-kill.
  mesonBuildType = "debugoptimized";
  mesonFlags = [
    "-Ddebug=false" # -O2 without -g: less compile RAM + smaller output
    "-Dwrap_mode=nodownload"
    "-Dremote=disabled"
    "-Dinference=disabled"
    "-Dtests=false"
    "-Dexamples=false"
    "-Dpython=false"
    "-Dnative=false"
  ];

  # Several compositor/runtime translation units combine large C++20 and
  # header-only dependency graphs. Four concurrent cc1plus processes exceed a
  # small builder's memory even at -O2 (observed as an OOM SIGKILL, not a source
  # diagnostic). Serialize this package so it is reliable on modest local and
  # self-hosted CI workers; the outer environment matrix remains parallel.
  enableParallelBuilding = false;

  meta = {
    description = "CyberEther: heterogeneous SDR signal visualisation (Vulkan/WebGPU)";
    homepage = "https://github.com/luigifcruz/CyberEther";
    license = lib.licenses.mit;
    platforms = [ "x86_64-linux" ];
    mainProgram = "cyberether";
  };
}
