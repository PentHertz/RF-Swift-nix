# PDU utilities (Sandia) (OOT for GNU Radio 3.10).
{ lib , fetchFromGitHub , gnuradioPackages , cmake , pkg-config , boost , spdlog , gmp , log4cpp , volk , fftwFloat , python3Packages }:

gnuradioPackages.mkDerivation {
  pname = "gr-pdu_utils";
  version = "3.10";

  src = fetchFromGitHub {
    owner = "PentHertz";
    repo = "gr-pdu_utils_resolute";
    rev = "af12810e762a81c7863f60dfbf9db32d7ae0f682";
    hash = "sha256-08TiyNHPw9mHVjjWRLE3f0+ifTtlHFae+r9XE8Ul4sE=";
  };

  nativeBuildInputs = [ cmake pkg-config python3Packages.pybind11 ];
  buildInputs = [ boost spdlog gmp log4cpp volk fftwFloat python3Packages.numpy ];
  cmakeFlags = [ "-DCMAKE_POLICY_VERSION_MINIMUM=3.5" ];
  env.NIX_CFLAGS_COMPILE = "-Wno-error -Wno-deprecated-declarations -Wno-narrowing -fpermissive";

  meta = {
    description = "PDU utilities (Sandia)";
    homepage = "https://github.com/PentHertz/gr-pdu_utils_resolute";
    license = lib.licenses.gpl3Plus;
    platforms = lib.platforms.linux;
  };
}
