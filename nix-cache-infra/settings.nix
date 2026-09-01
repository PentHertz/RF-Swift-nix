# Site-specific settings for the RF-Swift Nix binary cache.
# Everything deployment-specific lives here; edit this file, then re-run
# `system-manager switch`. Secrets do NOT go here (they live in
# /etc/atticd/atticd.env on the VPS, outside git and the Nix store).
{
  # Public hostnames. Point DNS A/AAAA records at your OVH VPS. Caddy issues a
  # TLS cert for each. Both proxy to the same attic server; the cache name in
  # the URL path selects dev vs release.
  devHost = "nixcache-dev.penthertz.com";
  releaseHost = "nixcache.penthertz.com";

  # Email used for the ACME (Let's Encrypt) account Caddy creates.
  acmeEmail = "admin@example.com";

  # OVH Object Storage (S3-compatible) that physically holds the cache data.
  # Find the endpoint/region in the OVH manager under Object Storage (S3 API).
  s3 = {
    endpoint = "https://s3.gra.io.cloud.ovh.net";
    region = "gra";
    bucket = "rfswift-nix-cache";
  };

  # attic listens only on loopback; Caddy is the sole public entry point.
  atticListenPort = 8080;

  # Logical caches created inside the single attic server.
  caches = {
    dev = "dev";
    release = "release";
  };

  # SECURITY: source ranges allowed to reach SSH (port 22). GitHub CI never
  # needs SSH (it pushes over HTTPS with a token), so lock this to your admin
  # IPs only. Leaving it open is the single biggest risk on this box.
  # Example: [ "203.0.113.4/32" "198.51.100.0/24" ]
  sshAllowedCIDRs = [ "0.0.0.0/0" ]; # <-- CHANGE ME before going live

  # Admin login user created by scripts/bootstrap.sh (root SSH is then disabled).
  adminUser = "deploy";
  # Paste the PUBLIC key(s) that may log in as the admin user.
  adminSSHKeys = [
    # "ssh-ed25519 AAAA... you@laptop"
  ];

  # zram compressed swap size. ~1x RAM with zstd is a safe headroom on a 2 GB VPS.
  zramSizeMiB = 2048;
}
