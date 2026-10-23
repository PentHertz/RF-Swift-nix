# radio astronomy signal processing (OOT for GNU Radio 3.10).
{ lib , fetchFromGitHub , gnuradioPackages , cmake , pkg-config , boost , spdlog , gmp , log4cpp , volk , fftwFloat , python3Packages , orc }:

gnuradioPackages.mkDerivation {
  pname = "gr-radio_astro";
  version = "3.10";

  src = fetchFromGitHub {
    owner = "WVURAIL";
    repo = "gr-radio_astro";
    rev = "ece44e158429325aa778b85bd3fd865f5b8e378e";
    hash = "sha256-9YLqNCQpALCC8/GdCN0vQJx3FgxahmVX9rRydNDFh7w=";
  };

  nativeBuildInputs = [ cmake pkg-config python3Packages.pybind11 ];
  buildInputs = [ boost spdlog gmp log4cpp volk fftwFloat python3Packages.numpy orc python3Packages.ephem ];
  # Python modules its blocks import at run time: propagated so a GNU Radio
  # wrapper bundling the module adds them to its Python environment.
  propagatedBuildInputs = [ python3Packages.ephem ];
  cmakeFlags = [ "-DCMAKE_POLICY_VERSION_MINIMUM=3.5" ];
  env.NIX_CFLAGS_COMPILE = "-Wno-error -Wno-deprecated-declarations -Wno-narrowing -fpermissive";

  meta = {
    description = "radio astronomy signal processing";
    homepage = "https://github.com/WVURAIL/gr-radio_astro";
    license = lib.licenses.gpl3Plus;
    platforms = lib.platforms.linux;
  };
}
