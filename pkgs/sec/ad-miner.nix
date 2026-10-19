# AD Miner at 1.9.0, the release RF-Swift-images' adminer_soft_install
# installs (ad). nixpkgs' recipe (1.8.1) is kept and moved forward:
#
#   * 1.9.0 adds requests to the dependencies;
#   * Python 3.14 (nixpkgs' python3) made "forkserver" the default
#     multiprocessing start method on Linux, and AD Miner's Pool workers read a
#     global (nodes_cache) only the parent sets. As the images do, force "fork",
#     the Linux default up to 3.13. (macOS has defaulted to "spawn", with the
#     same effect, since 3.8; the patch applies there too.)
{ ad-miner, fetchFromGitHub, python3 }:

ad-miner.overridePythonAttrs (old: {
  version = "1.9.0";

  src = fetchFromGitHub {
    owner = "AD-Security";
    repo = "AD_Miner";
    tag = "v1.9.0";
    hash = "sha256-OCNwX72LgFRXdz2DrM64kHSfHtQchk5MAzQRyUZTV+w=";
  };

  postPatch = (old.postPatch or "") + ''
    sed -i '1a import multiprocessing as _rfswift_mp; _rfswift_mp.set_start_method("fork", force=True)  # RF Swift: py3.14 defaults to forkserver' \
      ad_miner/__main__.py
  '';

  dependencies = old.dependencies ++ [ python3.pkgs.requests ];

  meta = old.meta // {
    changelog = "https://github.com/AD-Security/AD_Miner/blob/v1.9.0/CHANGELOG.md";
  };
})
