{ lib, stdenv, fetchFromGitHub, autoreconfHook, pkg-config, bison, flex, libnfc, readline, openssl }:
stdenv.mkDerivation {
  pname = "mfterm"; version = "unstable";
  src = fetchFromGitHub { owner = "4ZM"; repo = "mfterm"; rev = "e13d373cc23c4e0b89f112b5e4e6d21f737d937e"; hash = "sha256-5qQpBeT9IX9gf9cL198iI1eSJJaweRfd0UDo7v3+L8w="; };
  nativeBuildInputs = [ autoreconfHook pkg-config bison flex ];
  buildInputs = [ libnfc readline openssl ];
  postPatch = "touch ChangeLog AUTHORS NEWS README";
  env.NIX_CFLAGS_COMPILE = "-Wno-error";
  meta = { description = "Interactive terminal for MIFARE Classic tags"; homepage = "https://github.com/4ZM/mfterm"; license = lib.licenses.gpl3Plus; mainProgram = "mfterm"; };
}
