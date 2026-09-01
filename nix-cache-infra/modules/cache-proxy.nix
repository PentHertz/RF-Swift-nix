# Caddy: the only public-facing service. Terminates TLS (automatic Let's
# Encrypt), enforces modern ciphers + security headers, and reverse-proxies to
# the loopback attic server. Both cache subdomains share one site block; the
# attic cache name in the URL path (/dev or /release) selects the cache.
{ config, lib, pkgs, ... }:
let
  s = import ../settings.nix;
  upstream = "127.0.0.1:${toString s.atticListenPort}";
in
{
  config = {
    environment.systemPackages = [ pkgs.caddy ];

    environment.etc."caddy/Caddyfile".text = ''
      {
        email ${s.acmeEmail}
        # Caddy negotiates TLS 1.2/1.3 with strong ciphers by default.
      }

      ${s.devHost}, ${s.releaseHost} {
        # Security headers. HSTS assumes you are committed to HTTPS on this host.
        header {
          Strict-Transport-Security "max-age=31536000; includeSubDomains"
          X-Content-Type-Options "nosniff"
          X-Frame-Options "DENY"
          Referrer-Policy "no-referrer"
          -Server
        }

        # Attic streams large NARs both ways; disable buffering and body limits.
        request_body {
          max_size 0
        }

        reverse_proxy ${upstream} {
          flush_interval -1
          transport http {
            read_timeout 1h
            write_timeout 1h
          }
        }

        log {
          output file /var/log/caddy/access.log
          format json
        }
      }
    '';

    systemd.services.caddy = {
      description = "Caddy reverse proxy / TLS termination for the Nix cache";
      wantedBy = [ "multi-user.target" ];
      after = [ "network-online.target" ];
      wants = [ "network-online.target" ];
      serviceConfig = {
        ExecStart = "${pkgs.caddy}/bin/caddy run --config /etc/caddy/Caddyfile --adapter caddyfile";
        ExecReload = "${pkgs.caddy}/bin/caddy reload --config /etc/caddy/Caddyfile --adapter caddyfile --force";
        DynamicUser = true;
        StateDirectory = "caddy"; # ACME certs + account key persist here
        LogsDirectory = "caddy";
        # Only capability needed: bind 80/443 as an unprivileged (dynamic) user.
        AmbientCapabilities = [ "CAP_NET_BIND_SERVICE" ];
        CapabilityBoundingSet = [ "CAP_NET_BIND_SERVICE" ];
        NoNewPrivileges = true;
        ProtectSystem = "strict";
        ProtectHome = true;
        PrivateTmp = true;
        ProtectKernelTunables = true;
        ProtectControlGroups = true;
        RestrictAddressFamilies = [ "AF_INET" "AF_INET6" "AF_UNIX" "AF_NETLINK" ];
        Restart = "on-failure";
        RestartSec = 5;
      };
    };
  };
}
