# atticd: the Nix binary cache server. Storage backend is OVH S3 (so the VPS
# stays tiny); metadata is a small local SQLite DB. All secrets come from
# /etc/atticd/atticd.env (created by scripts/bootstrap.sh, chmod 600) so they
# never land in the world-readable /nix/store.
{ config, lib, pkgs, ... }:
let
  s = import ../settings.nix;
in
{
  config = {
    environment.systemPackages = [ pkgs.attic-client pkgs.attic-server ];

    environment.etc."atticd/server.toml".text = ''
      # Loopback only - Caddy is the sole public entry point (TLS + tokens).
      listen = "127.0.0.1:${toString s.atticListenPort}"

      # Clients must present a valid token; there is no anonymous access.
      # (Tokens are minted from the HS256 secret in atticd.env - see SETUP.md.)
      allowed-hosts = ["${s.devHost}", "${s.releaseHost}"]
      api-endpoint = "https://${s.releaseHost}/"

      require-proof-of-possession = true

      [database]
      url = "sqlite:///var/lib/atticd/server.db?mode=rwc"

      [storage]
      type = "s3"
      region = "${s.s3.region}"
      bucket = "${s.s3.bucket}"
      endpoint = "${s.s3.endpoint}"

      # Content-defined chunking: dedups NARs across builds to cut S3 usage.
      [chunking]
      nar-size-threshold = 65536
      min-size = 16384
      avg-size = 65536
      max-size = 262144

      [compression]
      type = "zstd"

      [garbage-collection]
      interval = "12 hours"
    '';

    systemd.services.atticd = {
      description = "Attic Nix binary cache server (OVH S3 backend)";
      wantedBy = [ "multi-user.target" ];
      after = [ "network-online.target" ];
      wants = [ "network-online.target" ];
      serviceConfig = {
        ExecStart = "${pkgs.attic-server}/bin/atticd -f /etc/atticd/server.toml";
        # Contains ATTIC_SERVER_TOKEN_HS256_SECRET_BASE64 + AWS_ACCESS_KEY_ID +
        # AWS_SECRET_ACCESS_KEY. Root-owned, mode 600, NOT in git or the store.
        EnvironmentFile = "/etc/atticd/atticd.env";
        DynamicUser = true;
        StateDirectory = "atticd";
        Restart = "on-failure";
        RestartSec = 5;

        # Sandbox hardening.
        NoNewPrivileges = true;
        ProtectSystem = "strict";
        ProtectHome = true;
        PrivateTmp = true;
        PrivateDevices = true;
        ProtectKernelTunables = true;
        ProtectKernelModules = true;
        ProtectControlGroups = true;
        ProtectClock = true;
        ProtectHostname = true;
        RestrictNamespaces = true;
        RestrictRealtime = true;
        RestrictSUIDSGID = true;
        LockPersonality = true;
        MemoryDenyWriteExecute = true;
        SystemCallArchitectures = "native";
        RestrictAddressFamilies = [ "AF_INET" "AF_INET6" "AF_UNIX" ];
        CapabilityBoundingSet = [ "" ];
      };
    };
  };
}
