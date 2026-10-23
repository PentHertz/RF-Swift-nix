# uv, at the version the images install (corebuild uvpython_install). 0.13.5
# moves the managed CPython builds `uv python install` downloads to
# python-build-standalone 20261021 (CPython 3.13.17 / 3.14.9 / 3.15.1), whose
# pip 26.2.2 and certifi 2026.10.19 no longer trust the compromised
# eMudhra/emSign root; 0.13.4 already dropped it from uv's own store.
# nixpkgs (2026-10-23) has 0.13.4. Once it catches up this returns the nixpkgs
# build, which cache.nixos.org serves, instead of rebuilding uv from source.
{ lib, uv, fetchFromGitHub }:

let
  version = "0.13.5";
in
if lib.versionAtLeast uv.version version then uv
else uv.overrideAttrs (finalAttrs: old: {
  inherit version;

  src = fetchFromGitHub {
    owner = "astral-sh";
    repo = "uv";
    tag = finalAttrs.version;
    hash = "sha256-SXTusm2EJ49tk03c3vSHcZp3AtAuj9SGOzsMwpnjXDw=";
  };

  cargoHash = "sha256-spQmSFAjNs6pWnw2nd/d3ZysIMK9j+BjDjrwcnUCmWw=";

  meta = old.meta // {
    changelog = "https://github.com/astral-sh/uv/blob/${finalAttrs.version}/CHANGELOG.md";
  };
})
