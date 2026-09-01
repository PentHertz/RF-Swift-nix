{
  description = "RF-Swift Nix binary cache: attic + OVH S3, hardened, managed with system-manager (Nix on non-NixOS)";

  inputs = {
    # Pin to a release channel for a stable, reproducible server. Bump deliberately.
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.11";
    system-manager = {
      url = "github:numtide/system-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, system-manager, ... }:
    let
      system = "x86_64-linux";
    in
    {
      # Apply on the VPS with:
      #   system-manager switch --flake .#default
      systemConfigs.default = system-manager.lib.makeSystemConfig {
        modules = [
          ./modules/attic.nix
          ./modules/cache-proxy.nix
          ./modules/hardening.nix
          ./modules/zram.nix
          ({ ... }: {
            config = {
              nixpkgs.hostPlatform = system;
              # system-manager refuses to run on unknown distros unless told it is
              # OK. OVH ships Debian/Ubuntu, both fine.
              system-manager.allowAnyDistro = true;
            };
          })
        ];
      };
    };
}
