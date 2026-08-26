# fdk-aac with argilo's HDC patch (adds the AOT_HDC object type HD Radio needs).
# gr-nrsc5 requires this fork; stock fdk-aac lacks AOT_HDC. Autotools build.
{ lib, stdenv, fetchFromGitHub, autoreconfHook }:

stdenv.mkDerivation {
  pname = "fdk-aac-hdc";
  version = "unstable-argilo";

  src = fetchFromGitHub {
    owner = "argilo";
    repo = "fdk-aac";
    rev = "3b63dab59416a629f3de82463eb3875319a086d5";
    hash = "sha256-7LV7lewh/XkmoU9m5iBqpZvVDYnBcYjte5phQbtU3/k=";
  };

  nativeBuildInputs = [ autoreconfHook ];

  meta = {
    description = "fdk-aac with the HDC (HD Radio) object-type patch";
    homepage = "https://github.com/argilo/fdk-aac";
    license = lib.licenses.unfree; # fdk-aac license (as in nixpkgs' fdk_aac)
    platforms = lib.platforms.linux;
  };
}
