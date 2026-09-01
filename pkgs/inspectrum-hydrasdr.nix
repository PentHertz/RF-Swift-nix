# inspectrum, HydraSDR fork. Overrides the nixpkgs inspectrum source.
{ lib, fetchFromGitHub, inspectrum }:

inspectrum.overrideAttrs (old: {
  pname = "inspectrum-hydrasdr";
  version = "unstable-hydrasdr";
  src = fetchFromGitHub {
    owner = "hydrasdr";
    repo = "inspectrum";
    rev = "ba807f05ddff42b02c7df3a7f9544374dbb519e6";
    hash = "sha256-/l3aLeXy4Ll3cC5Np6WuPJbTFeZK23qGSDNFOGyRsgI=";
  };
  # nixpkgs' postPatch rewrites a specific cmake_minimum_required line that the
  # fork may not have (--replace-fail). Drop it and relax the policy minimum
  # directly, which achieves the same without depending on the exact source.
  postPatch = "";
  cmakeFlags = (old.cmakeFlags or [ ]) ++ [ "-DCMAKE_POLICY_VERSION_MINIMUM=3.5" ];
  meta = (old.meta or { }) // {
    description = "inspectrum (HydraSDR fork): offline radio signal analyzer";
    homepage = "https://github.com/hydrasdr/inspectrum";
  };
})
