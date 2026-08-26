# POCSAG pager encoder (OOT for GNU Radio 3.10).
{ lib , fetchFromGitHub , gnuradioPackages , cmake , pkg-config , boost , spdlog , gmp , log4cpp , volk , fftwFloat , python3Packages, itpp }:

gnuradioPackages.mkDerivation {
  pname = "gr-mixalot";
  version = "3.10";

  src = fetchFromGitHub {
    owner = "unsynchronized";
    repo = "gr-mixalot";
    rev = "beae13525fecd4e62819a6b6b4544a9185835182";
    hash = "sha256-4TiqWuHZiS0UQX7uekN8g/+4EUeb7ODMTbc6L9b7GlI=";
  };

  nativeBuildInputs = [ cmake pkg-config python3Packages.pybind11 ];
  buildInputs = [ boost spdlog gmp log4cpp volk fftwFloat python3Packages.numpy itpp ];
  cmakeFlags = [ "-DCMAKE_POLICY_VERSION_MINIMUM=3.5" ];
  env.NIX_CFLAGS_COMPILE = "-Wno-error -Wno-deprecated-declarations -Wno-narrowing -fpermissive";

  meta = {
    description = "POCSAG pager encoder";
    homepage = "https://github.com/unsynchronized/gr-mixalot";
    license = lib.licenses.gpl3Plus;
    platforms = lib.platforms.linux;
  };
}
