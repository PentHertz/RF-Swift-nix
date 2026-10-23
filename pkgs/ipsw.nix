# ipsw, at the version the images install (mobile_software
# ios_tools_soft_install); nixpkgs (2026-10-23) has 3.1.736. Since 3.1.737 its
# go.mod requires Go >= 1.27, which nixpkgs' default buildGoModule (Go 1.26)
# rejects. Returns the nixpkgs build once nixpkgs catches up.
{ lib, ipsw, fetchFromGitHub, buildGo127Module }:

let
  version = "3.1.739";
in
if lib.versionAtLeast ipsw.version version then ipsw
else (ipsw.override { buildGoModule = buildGo127Module; }).overrideAttrs (finalAttrs: old: {
  inherit version;

  src = fetchFromGitHub {
    owner = "blacktop";
    repo = "ipsw";
    tag = "v${finalAttrs.version}";
    hash = "sha256-IcQuXqX3LULmU9jvl4+wBJ7OtMYV5+lQZUIlogWfmyI=";
  };

  vendorHash = "sha256-VHzeNvNfgenYGD4QdtZMLUK3Cy7/Wmdxo3ODetWdxBk=";
})
