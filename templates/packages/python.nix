{ callPackage, lib }:

(callPackage ./lib/mkGitHubTool.nix { }) {
  pname = "@NAME@";
  version = "0-unstable-@DATE@";
  build = "python";
  source = { owner = "@OWNER@"; repo = "@REPO@"; updateBranch = "@BRANCH@"; rev = "@REV@"; hash = lib.fakeHash; };
  pythonImportsCheck = [ "@PYMODULE@" ];
  description = "TODO: describe @NAME@";
  license = "mit";
}
