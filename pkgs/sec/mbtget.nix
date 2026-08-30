# mbtget (sourceperl/mbtget): a simple Modbus/TCP client written in Perl,
# building with the standard ExtUtils::MakeMaker flow (perl Makefile.PL / make /
# make install). Matches RF-Swift-images' mbtget_soft_install.
{ lib, perlPackages, fetchFromGitHub }:

perlPackages.buildPerlPackage {
  pname = "mbtget";
  version = "1.1.7-unstable-2026-08-30";

  src = fetchFromGitHub {
    owner = "sourceperl";
    repo = "mbtget";
    rev = "053cee0659a737e172892f6a5800f5d667ff572d";
    hash = "sha256-KqaquRpn0eYz/SsfDEtbgnw/E78y8JWK19ry4jM6AgI=";
  };

  outputs = [ "out" ];
  doCheck = false;

  meta = {
    description = "Modbus/TCP client (Perl) for reading and writing PLC registers";
    homepage = "https://github.com/sourceperl/mbtget";
    license = lib.licenses.gpl3Plus;
    platforms = lib.platforms.unix;
    mainProgram = "mbtget";
  };
}
