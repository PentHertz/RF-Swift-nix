{ callPackage, lib }:

(callPackage ./lib/mkGitHubTool.nix { }) {
  pname = "@NAME@";
  version = "0-unstable-@DATE@";
  build = "rust";
  source = { owner = "@OWNER@"; repo = "@REPO@"; updateBranch = "@BRANCH@"; rev = "@REV@"; hash = lib.fakeHash; };
  cargoHash = lib.fakeHash;
  description = "TODO: describe @NAME@";
  license = "mit";
}
