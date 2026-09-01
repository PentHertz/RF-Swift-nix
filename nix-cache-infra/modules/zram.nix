# Compressed RAM swap (zram) - cheap OOM headroom for a 2 GB VPS. zstd gives
# roughly 3:1, so a 2 GiB zram device costs little real RAM while absorbing
# spikes (atticd chunking, Caddy under load, unattended-upgrades).
{ config, lib, pkgs, ... }:
let
  s = import ../settings.nix;
in
{
  config = {
    systemd.services.zram-swap = {
      description = "zram compressed swap device";
      wantedBy = [ "multi-user.target" ];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        ExecStartPre = "${pkgs.kmod}/bin/modprobe zram";
        ExecStart = pkgs.writeShellScript "zram-up" ''
          set -eu
          dev=/dev/zram0
          ${pkgs.util-linux}/bin/zramctl --reset "$dev" 2>/dev/null || true
          ${pkgs.util-linux}/bin/zramctl "$dev" --algorithm zstd --size ${toString s.zramSizeMiB}MiB
          ${pkgs.util-linux}/bin/mkswap "$dev"
          ${pkgs.util-linux}/bin/swapon --priority 100 "$dev"
        '';
        ExecStop = pkgs.writeShellScript "zram-down" ''
          set -eu
          ${pkgs.util-linux}/bin/swapoff /dev/zram0 2>/dev/null || true
          ${pkgs.util-linux}/bin/zramctl --reset /dev/zram0 2>/dev/null || true
        '';
      };
    };

    # Prefer swapping only under real pressure (protects SSD-less/low-IO VPS).
    environment.etc."sysctl.d/98-zram.conf".text = ''
      vm.swappiness = 60
      vm.page-cluster = 0
    '';
  };
}
