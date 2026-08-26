# HD Radio (NRSC-5) decoder (OOT for GNU Radio 3.10).
{ lib , fetchFromGitHub , gnuradioPackages , cmake , pkg-config , boost , spdlog , gmp , log4cpp , volk , fftwFloat , python3Packages, gsl, fftw, git, fdk_aac }:

gnuradioPackages.mkDerivation {
  pname = "gr-nrsc5";
  version = "3.10";

  src = fetchFromGitHub {
    owner = "argilo";
    repo = "gr-nrsc5";
    rev = "85eb342ba78b337032bf070302722968d01c179b";
    hash = "sha256-4sDh/u93Qpkxkh/voeaOZjNH5Zlq+9AvVeTHxVt3mPI=";
  };

  nativeBuildInputs = [ cmake pkg-config git python3Packages.pybind11 ];
  buildInputs = [ boost spdlog gmp log4cpp volk fftwFloat python3Packages.numpy gsl fftw fdk_aac ];
  # Point at the fdk-aac-hdc fork (argilo, passed in as fdk_aac from default.nix)
  # so CMake takes the "use system lib" branch instead of git-cloning it via
  # ExternalProject (the offline builder cannot fetch). The HDC-patched fork is
  # required: gr-nrsc5 uses its AOT_HDC object type, absent from stock fdk-aac.
  cmakeFlags = [
    "-DCMAKE_POLICY_VERSION_MINIMUM=3.5"
    "-DFDK_AAC_LIBRARY=${fdk_aac}/lib/libfdk-aac.so"
    "-DFDK_AAC_INCLUDE_DIR=${fdk_aac}/include"
  ];
  env.NIX_CFLAGS_COMPILE = "-Wno-error -Wno-deprecated-declarations -Wno-narrowing -fpermissive";

  meta = {
    description = "HD Radio (NRSC-5) decoder";
    homepage = "https://github.com/argilo/gr-nrsc5";
    license = lib.licenses.gpl3Plus;
    platforms = lib.platforms.linux;
  };
}
