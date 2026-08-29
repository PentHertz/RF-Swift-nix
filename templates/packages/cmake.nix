{ callPackage, lib }:

(callPackage ./lib/mkGitHubTool.nix { }) {
  pname = "@NAME@";
  version = "0-unstable-@DATE@";
  build = "cmake";
  source = { owner = "@OWNER@"; repo = "@REPO@"; updateBranch = "@BRANCH@"; rev = "@REV@"; hash = lib.fakeHash; };
  description = "TODO: describe @NAME@";
  license = "mit";
}
