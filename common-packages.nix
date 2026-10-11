# Baseline tools available in every RF Swift environment (pure data, like
# environments.nix). Imported by flake.nix, which prepends them to each
# environment's packages, and by gen-catalog.nix, so the catalog the CLI/GUI
# read lists exactly what an environment ships.
#
# The CLI part mirrors RF-Swift-images' corebuild common_utils_install, the
# layer every image is built on. Left out on purpose:
#   * meld and recoll (+ its document filters): heavy GUI applications that a
#     desktop host already provides;
#   * iputils (ping) and util-linux (bsdextrautils' column/hexdump, but also
#     mount/su): the host's copies carry setuid bits or file capabilities that
#     a Nix store path cannot, so shadowing them on PATH would break them.
[
  # Toolchains
  "python3"
  "uv"
  "go"
  # Diff / compare, hex and binary viewers, text and data processing
  "colordiff"
  "delta"
  "xxd"
  "hexyl"
  "file"
  "jq"
  "yq"
  "ripgrep"
  "fd"
  "bat"
  "dos2unix"
  "moreutils"
  "less"
  "nano"
  # Terminal and system monitoring, archives, process debugging
  "tmux"
  "mc"
  "tree"
  "ncdu"
  "htop"
  "btop"
  "pv"
  "bc"
  "tealdeer"
  "_7zz"
  "zip"
  "xz"
  "zstd"
  "lsof"
  "strace"
  "ltrace"
  # Network clients and X11 clipboard helpers
  "openssh"
  "net-tools"
  "traceroute"
  "dnsutils"
  "xclip"
  "xsel"
]
