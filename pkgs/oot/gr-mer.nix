# Modulation Error Ratio measurement (OOT for GNU Radio 3.10).
{ lib , fetchFromGitHub , gnuradioPackages , cmake , pkg-config , boost , spdlog , gmp , log4cpp , volk , fftwFloat , python3Packages }:

gnuradioPackages.mkDerivation {
  pname = "gr-mer";
  version = "3.10";

  src = fetchFromGitHub {
    owner = "git-artes";
    repo = "gr-mer";
    rev = "dafeae21ec79e3034e827f3ced0626c9f5aad21f";
    hash = "sha256-tpzfgs7Brfl8WkkLY/gCtEgp93YWSu6poT+e2vmCPn4=";
  };

  nativeBuildInputs = [ cmake pkg-config python3Packages.pybind11 ];
  buildInputs = [ boost spdlog gmp log4cpp volk fftwFloat python3Packages.numpy ];
  cmakeFlags = [ "-DCMAKE_POLICY_VERSION_MINIMUM=3.5" ];
  env.NIX_CFLAGS_COMPILE = "-Wno-error -Wno-deprecated-declarations -Wno-narrowing -fpermissive";

  meta = {
    description = "Modulation Error Ratio measurement";
    homepage = "https://github.com/git-artes/gr-mer";
    license = lib.licenses.gpl3Plus;
    platforms = lib.platforms.linux;
  };
}
