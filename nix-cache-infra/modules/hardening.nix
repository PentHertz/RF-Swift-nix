# Host hardening, all declared in Nix: an nftables firewall (default-drop,
# SSH rate-limited and locked to admin CIDRs), kernel sysctl hardening, an sshd
# drop-in (key-only, no root), and fail2ban as defense-in-depth.
{ config, lib, pkgs, ... }:
let
  s = import ../settings.nix;
  sshAllow = lib.concatStringsSep ", " s.sshAllowedCIDRs;
in
{
  config = {
    environment.systemPackages = [ pkgs.nftables pkgs.fail2ban ];

    ##########################################################################
    # Firewall: only 80/443 open to the world; SSH restricted + rate-limited.
    ##########################################################################
    environment.etc."nftables.conf".text = ''
      #!/usr/sbin/nft -f
      flush ruleset

      table inet filter {
        chain input {
          type filter hook input priority 0; policy drop;

          iif "lo" accept
          ct state established,related accept
          ct state invalid drop

          # Minimal ICMP for path-MTU / diagnostics.
          ip protocol icmp icmp type { echo-request, destination-unreachable, time-exceeded, parameter-problem } accept
          ip6 nexthdr ipv6-icmp accept

          # SSH: only from admin ranges, and rate-limited against brute force.
          ip saddr { ${sshAllow} } tcp dport 22 ct state new limit rate 6/minute burst 6 packets accept
          ip saddr { ${sshAllow} } tcp dport 22 ct state new drop

          # Public cache + ACME challenges.
          tcp dport { 80, 443 } accept

          # Everything else is dropped by policy.
        }

        chain forward { type filter hook forward priority 0; policy drop; }
        chain output  { type filter hook output priority 0; policy accept; }
      }
    '';

    systemd.services.nftables = {
      description = "nftables firewall";
      wantedBy = [ "multi-user.target" ];
      before = [ "network-pre.target" ];
      wants = [ "network-pre.target" ];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        ExecStart = "${pkgs.nftables}/bin/nft -f /etc/nftables.conf";
        ExecReload = "${pkgs.nftables}/bin/nft -f /etc/nftables.conf";
        ExecStop = "${pkgs.nftables}/bin/nft flush ruleset";
      };
    };

    ##########################################################################
    # Kernel sysctl hardening. Applied on switch via systemd-sysctl.
    ##########################################################################
    environment.etc."sysctl.d/99-cache-hardening.conf".text = ''
      # Network
      net.ipv4.conf.all.rp_filter = 1
      net.ipv4.conf.default.rp_filter = 1
      net.ipv4.conf.all.accept_redirects = 0
      net.ipv6.conf.all.accept_redirects = 0
      net.ipv4.conf.all.send_redirects = 0
      net.ipv4.conf.all.accept_source_route = 0
      net.ipv6.conf.all.accept_source_route = 0
      net.ipv4.tcp_syncookies = 1
      net.ipv4.conf.all.log_martians = 1
      # Kernel
      kernel.kptr_restrict = 2
      kernel.dmesg_restrict = 1
      kernel.yama.ptrace_scope = 1
      fs.protected_hardlinks = 1
      fs.protected_symlinks = 1
    '';

    systemd.services.apply-sysctl = {
      description = "Apply hardened sysctl settings";
      wantedBy = [ "multi-user.target" ];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        ExecStart = "${pkgs.procps}/bin/sysctl --system";
      };
    };

    ##########################################################################
    # sshd hardening drop-in. The distro's sshd includes /etc/ssh/sshd_config.d/*.
    # bootstrap.sh creates the admin user + keys BEFORE this disables root login.
    ##########################################################################
    environment.etc."ssh/sshd_config.d/99-cache-hardening.conf".text = ''
      PermitRootLogin no
      PasswordAuthentication no
      KbdInteractiveAuthentication no
      ChallengeResponseAuthentication no
      PubkeyAuthentication yes
      PermitEmptyPasswords no
      X11Forwarding no
      AllowAgentForwarding no
      AllowTcpForwarding no
      MaxAuthTries 3
      MaxSessions 4
      LoginGraceTime 20
      ClientAliveInterval 300
      ClientAliveCountMax 2
      AllowUsers ${s.adminUser}
    '';

    ##########################################################################
    # fail2ban: bans hosts that hammer sshd. Uses the nftables backend.
    ##########################################################################
    environment.etc."fail2ban/jail.local".text = ''
      [DEFAULT]
      banaction = nftables-multiport
      backend = systemd
      bantime = 1h
      findtime = 10m
      maxretry = 5

      [sshd]
      enabled = true
      port = ssh
    '';

    systemd.services.fail2ban = {
      description = "fail2ban intrusion prevention";
      wantedBy = [ "multi-user.target" ];
      after = [ "nftables.service" ];
      serviceConfig = {
        Type = "simple";
        ExecStartPre = "${pkgs.coreutils}/bin/mkdir -p /var/run/fail2ban";
        ExecStart = "${pkgs.fail2ban}/bin/fail2ban-server -xf -s /var/run/fail2ban/fail2ban.sock -p /var/run/fail2ban/fail2ban.pid";
        Restart = "on-failure";
        RestartSec = 5;
      };
    };
  };
}
