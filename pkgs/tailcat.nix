# Tailcat: netcat over Tailscale's WireGuard/DERP data plane without the
# Tailscale control plane or a Tailscale account.
{ lib, buildGoModule, fetchFromGitHub }:

buildGoModule {
  pname = "tailcat";
  version = "0-unstable-2026-08-27";

  src = fetchFromGitHub {
    owner = "tailscale";
    repo = "tailcat";
    rev = "c04c5afee401df40e620db8ae108e957ae07bcd9";
    hash = "sha256-QqlGCmT/RRcAJKvwa+0nwYou8yp4kx3kAm1gIkljyGo=";
  };

  vendorHash = "sha256-3uVUHATnd2s+Axdq06/xAQ2IbzJZfP1yQ/nEopgckq0=";
  subPackages = [ "cmd/tailcat" ];

  meta = {
    description = "Netcat over Tailscale's data plane without its control plane";
    homepage = "https://github.com/tailscale/tailcat";
    license = lib.licenses.bsd3;
    mainProgram = "tailcat";
  };
}
