# OP25: P25 digital voice/trunking decoder (boatbod fork). master is the GNU
# Radio 3.10 line since 2024-12. The repo root CMake builds both OOT modules
# (gr-op25, gr-op25_repeater); the runnable apps live under the repeater's apps/.
# The IMBE/AMBE vocoder is vendored in-tree (no itpp / no libpcap needed).
{ lib, fetchFromGitHub, gnuradioPackages, cmake, pkg-config, cppunit
, boost, spdlog, gmp, volk, libsndfile, orc, gr-osmosdr-penthertz
, python3Packages, makeWrapper }:

gnuradioPackages.mkDerivation {
  pname = "op25";
  version = "master";

  src = fetchFromGitHub {
    owner = "boatbod";
    repo = "op25";
    rev = "71abcd0ead32f86f51615ea6cc8a6a4dba4c949a";
    hash = "sha256-PfMLhd4FiKr8EN8444yms+0s4Hv0C46rggdeth3pO0Q=";
  };

  nativeBuildInputs = [ cmake pkg-config cppunit python3Packages.pybind11 makeWrapper ];
  buildInputs = [ boost spdlog gmp volk libsndfile orc gr-osmosdr-penthertz ]
    ++ (with python3Packages; [ numpy pyqt5 requests waitress ]);

  cmakeFlags = [ "-DCMAKE_POLICY_VERSION_MINIMUM=3.5" ];
  env.NIX_CFLAGS_COMPILE = "-Wno-error";

  # CMake 4 removed policies CMP0026 / CMP0045, so the explicit "SET ... OLD"
  # calls error out. Drop them; under the 3.5 policy minimum they default to NEW.
  postPatch = ''
    find . -name CMakeLists.txt -exec sed -i \
      -e '/cmake_policy(SET CMP0026 OLD)/d' \
      -e '/cmake_policy(SET CMP0045 OLD)/d' {} +
  '';

  # Expose the runnable apps (rx.py, multi_rx.py) that live in the repeater's
  # apps/ dir, wrapped with the op25 Python module on PYTHONPATH.
  postInstall = ''
    appdir=$out/share/op25/apps
    mkdir -p $appdir $out/bin
    if [ -d "$NIX_BUILD_TOP/source/op25/gr-op25_repeater/apps" ]; then
      cp -r "$NIX_BUILD_TOP/source/op25/gr-op25_repeater/apps/"* $appdir/ || true
      for app in rx multi_rx; do
        if [ -f "$appdir/$app.py" ]; then
          makeWrapper ${python3Packages.python.interpreter} $out/bin/op25-$app \
            --add-flags "$appdir/$app.py" \
            --chdir "$appdir" \
            --prefix PYTHONPATH : "$out/${python3Packages.python.sitePackages}:$PYTHONPATH"
        fi
      done
    fi
  '';

  meta = {
    description = "OP25: APCO P25 digital voice and trunking decoder (boatbod fork)";
    homepage = "https://github.com/boatbod/op25";
    license = lib.licenses.gpl3Plus;
    platforms = lib.platforms.linux;
  };
}
