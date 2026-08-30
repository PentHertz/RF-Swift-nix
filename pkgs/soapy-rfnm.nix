# soapy-rfnm: SoapySDR module for the RFNM SDR (rfnm), on librfnm. Matches the
# sdr_light image's soapyrfnm_grmod_install. Wired into soapysdr-with-plugins
# so SoapySDR-based apps discover it.
{ lib, stdenv, fetchFromGitHub, cmake, pkg-config, cpm-cmake, soapysdr, librfnm, spdlog }:

stdenv.mkDerivation {
  pname = "soapy-rfnm";
  version = "unstable-rfnm";

  src = fetchFromGitHub {
    owner = "rfnm";
    repo = "soapy-rfnm";
    rev = "0098ac2629b59a94b2a6c7a84afd89dfead3e829";
    hash = "sha256-BUDdk0q//z7cS5mOKAsFRKhKIHfm09pYwoRtAnLVsWM=";
  };

  # Upstream's cmake/cpm.cmake is only a bootstrap that downloads CPM.cmake at
  # configure time; swap in nixpkgs' copy (same API, newer version).
  postPatch = ''
    cp ${cpm-cmake}/share/cpm/CPM.cmake cmake/cpm.cmake
  '';

  nativeBuildInputs = [ cmake pkg-config ];
  buildInputs = [ soapysdr librfnm ];
  # Upstream vendors spdlog through CPM (a GitHub download at configure time,
  # impossible in the sandbox). CPM honours CPM_<name>_SOURCE, so hand it the
  # spdlog source tree from nixpkgs; it is then built in-tree as upstream intends.
  cmakeFlags = [
    "-DSoapySDR_DIR=${soapysdr}/share/cmake/SoapySDR/"
    "-DCPM_spdlog_SOURCE=${spdlog.src}"
    "-DCMAKE_POLICY_VERSION_MINIMUM=3.5"
  ];

  meta = {
    description = "SoapySDR module for RFNM devices";
    homepage = "https://github.com/rfnm/soapy-rfnm";
    license = lib.licenses.mit;
    platforms = lib.platforms.unix;
  };
}
