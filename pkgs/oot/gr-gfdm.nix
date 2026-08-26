# Generalized Frequency Division Multiplexing (OOT for GNU Radio 3.10).
{ lib , fetchFromGitHub , gnuradioPackages , cmake , pkg-config , boost , spdlog , gmp , log4cpp , volk , fftwFloat , python3Packages, fmt }:

gnuradioPackages.mkDerivation {
  pname = "gr-gfdm";
  version = "3.10";

  src = fetchFromGitHub {
    owner = "bkerler";
    repo = "gr-gfdm";
    rev = "f1661a7121d4b3e038a18b9884745fe798ff5727";
    hash = "sha256-B9qlEzm4ZDsmUwutLYtMFRNUs1CW1LIiK0d+p+6UgUQ=";
  };

  nativeBuildInputs = [ cmake pkg-config python3Packages.pybind11 ];
  buildInputs = [ boost spdlog gmp log4cpp volk fftwFloat python3Packages.numpy fmt ];
  postPatch = ''
    for x in $(grep -rl 'fmt::format' lib include python 2>/dev/null); do
      sed -i '1i #include <fmt/format.h>' "$x"
    done
  '';
  cmakeFlags = [ "-DCMAKE_POLICY_VERSION_MINIMUM=3.5" ];
  env.NIX_CFLAGS_COMPILE = "-Wno-error -Wno-deprecated-declarations -Wno-narrowing -fpermissive";

  meta = {
    description = "Generalized Frequency Division Multiplexing";
    homepage = "https://github.com/bkerler/gr-gfdm";
    license = lib.licenses.gpl3Plus;
    platforms = lib.platforms.linux;
  };
}
