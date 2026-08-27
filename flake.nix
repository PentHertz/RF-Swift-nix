{
  description = "RF Swift - reproducible RF / hardware / security tool environments, powered by Nix";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    # Some tools (Mirage, bluing) require Python 3.10, which nixos-unstable has
    # dropped. Pin an older nixpkgs that still ships python310 just for those.
    nixpkgs-py310.url = "github:NixOS/nixpkgs/nixos-24.11";
  };

  outputs = { self, nixpkgs, nixpkgs-py310, ... }:
    let
      # Systems RF Swift Nix environments are built for.
      systems = [ "x86_64-linux" "aarch64-linux" "riscv64-linux" "x86_64-darwin" "aarch64-darwin" ];

      # The environment catalog (pure data): { <image> = { description; packages = [str]; ... }; }
      environments = import ./environments.nix;

      forAllSystems = f: nixpkgs.lib.genAttrs systems (system: f system);

      # On macOS, python3Packages.pyqt6 pulls qtwebengine via its `withPdf`
      # default. qtwebengine is not cached for aarch64-darwin and its source
      # build segfaults (in patchShebangs over the Chromium tree), which makes
      # every Qt-GUI Python tool — pyqtgraph, and therefore GNU Radio's
      # gnuradio-companion — impossible to build on macOS. pyqtgraph/GNU Radio
      # do not use QtPdf/QtWebEngine, so drop it on Darwin. Linux keeps the full
      # pyqt6 (qtwebengine is cached upstream there).
      pyqtNoWebengineOverlay = final: prev:
        prev.lib.optionalAttrs prev.stdenv.hostPlatform.isDarwin {
          pythonPackagesExtensions = (prev.pythonPackagesExtensions or [ ]) ++ [
            (pyfinal: pyprev: {
              pyqt6 = pyprev.pyqt6.override { withPdf = false; };
            })
          ];
        };

      # Allow unfree so the few tools that need it (and any vendor bits we add
      # later) resolve.
      pkgsFor = system: import nixpkgs {
        inherit system;
        config = {
          allowUnfree = true;
          allowBroken = false;
          # `objection` depends on the Android SDK. Without this, forcing the
          # android buildEnv fails even though a shallow devShell eval passes.
          android_sdk.accept_license = true;
        };
        overlays = [ pyqtNoWebengineOverlay ];
      };

      lib = nixpkgs.lib;

      # A python310 package set for the few tools that need it (Mirage, bluing).
      py310For = system:
        if builtins.elem system (builtins.attrNames (nixpkgs-py310.legacyPackages or { }))
        then import nixpkgs-py310 { inherit system; config = { allowUnfree = true; }; }
        else null;

      # RF Swift's own derivations: the PentHertz / HydraSDR forks and the
      # source-built tools that are not in nixpkgs. These take priority over a
      # nixpkgs attribute of the same name.
      customFor = system: import ./pkgs {
        pkgs = pkgsFor system;
        py310 = py310For system;
      };

      # Resolve one "attr.path" string into a package, preferring RF Swift's own
      # package set, then falling back to nixpkgs. Returns null if absent so a
      # single unavailable tool never breaks a whole environment.
      #
      # tryEval guards against nixpkgs "throwing aliases" (a renamed/removed
      # package whose attribute still exists but raises on access, e.g.
      # dump1090 -> dump1090-fa). Those are treated as absent, not fatal.
      resolvePkg = pkgs: custom: name:
        let
          raw =
            if builtins.hasAttr name custom then custom.${name}
            else lib.attrByPath (lib.splitString "." name) null pkgs;
          t = builtins.tryEval raw;
          available = t.success && t.value != null
            && lib.meta.availableOn pkgs.stdenv.hostPlatform t.value;
          # Some top-level packages claim broad platform support while a deep
          # dependency rejects the host (for example QtWebEngine on riscv64).
          # Force drvPath under tryEval so one such package is reported absent
          # instead of making the entire environment impossible to evaluate.
          forced = if available then builtins.tryEval t.value.drvPath else { success = false; };
        in if available && forced.success
           then t.value
           else null;

      resolveEnv = system: env:
        let
          pkgs = pkgsFor system;
          custom = customFor system;
          prerequisites = env.prerequisites or [];
          declared = env.packages;
          resolved = assert lib.assertMsg
            (lib.all (name: builtins.elem name declared) prerequisites)
            "RF-Swift-nix: every prerequisite must also be listed in packages";
            map (name: { inherit name; drv = resolvePkg pkgs custom name; }) declared;
          present = builtins.filter (x: x.drv != null) resolved;
          absent = builtins.filter (x: x.drv == null) resolved;
          note = lib.optionalString (absent != [])
            (builtins.trace
              "RF-Swift-nix: ${builtins.toString (builtins.length absent)} package(s) unavailable on ${system}: ${lib.concatMapStringsSep ", " (x: x.name) absent}"
              "");
        in {
          drvs = map (x: x.drv) present;
          absent = map (x: x.name) absent;
          _note = note;
        };

      mkShellFor = system: name: env:
        let
          pkgs = pkgsFor system;
          r = resolveEnv system env;
        in pkgs.mkShell {
          name = "rfswift-${name}";
          buildInputs = r.drvs;
          shellHook = ''
            echo ""
            echo "  RF Swift (Nix) - ${name} environment"
            echo "  ${env.description}"
            echo "  ${builtins.toString (builtins.length r.drvs)} tools available on PATH."
            echo ""
          '' + r._note;
        };

      # A single closure of all the environment's tools, installable with
      # `nix profile install .#<image>`.
      mkEnvFor = system: name: env:
        let
          pkgs = pkgsFor system;
          r = resolveEnv system env;
        in pkgs.buildEnv {
          name = "rfswift-${name}";
          paths = r.drvs;
          ignoreCollisions = true;
        };

      # A separately addressable prerequisite closure used by the RF Swift CLI
      # to realise runtime libraries/device plugins before user applications.
      mkPrereqFor = system: name: env:
        let
          pkgs = pkgsFor system;
          custom = customFor system;
          names = env.prerequisites or [];
          resolved = map (n: resolvePkg pkgs custom n) names;
        in pkgs.buildEnv {
          name = "rfswift-${name}-prerequisites";
          paths = builtins.filter (p: p != null) resolved;
          ignoreCollisions = true;
        };
    in
    {
      version = "1.0.0-dev";
      # devShells.<system>.<image> - entered with `nix develop .#<image>`
      devShells = forAllSystems (system:
        lib.mapAttrs (name: env: mkShellFor system name env) environments
        // { default = mkShellFor system "sdr_light" (environments.sdr_light or (builtins.head (builtins.attrValues environments))); }
      );

      # packages.<system>.<image> - buildEnv closures, installable into a profile.
      # Also exposes RF Swift's individual derivations under packages.<system>.pkg-<name>
      # so you can build one tool with `nix build .#pkg-readsb`.
      packages = forAllSystems (system:
        (lib.mapAttrs (name: env: mkEnvFor system name env) environments)
        // (lib.mapAttrs' (name: env:
          lib.nameValuePair "${name}-prerequisites" (mkPrereqFor system name env))
          (lib.filterAttrs (_: env: (env.prerequisites or []) != []) environments))
        // (lib.mapAttrs' (n: v: lib.nameValuePair "pkg-${n}" v) (customFor system))
      );

      # RF Swift's own package set, for reuse as an overlay input elsewhere.
      overlays.default = final: prev: import ./pkgs { pkgs = prev; };

      # The full pinned package set (nixpkgs + RF Swift's own derivations), so a
      # single tool can be built and run on demand:
      #   nix run github:PentHertz/RF-Swift-nix#gqrx
      #   nix run github:PentHertz/RF-Swift-nix#readsb
      # This is what the RF Swift "lazy" environment mode uses to build tools
      # step by step, the first time each is called, instead of all at once.
      legacyPackages = forAllSystems (system:
        import nixpkgs {
          inherit system;
          config = {
            allowUnfree = true;
            android_sdk.accept_license = true;
          };
          overlays = [ self.overlays.default pyqtNoWebengineOverlay ];
        });

      # The raw catalog, exposed for tooling / `nix eval .#catalog`
      catalog = environments;

      # `nix run .#gen-catalog` regenerates catalog.json from environments.nix
      apps = forAllSystems (system:
        let pkgs = pkgsFor system; in {
          gen-catalog = {
            type = "app";
            program = toString (pkgs.writeShellScript "gen-catalog" ''
              set -eu
              cd "$(git rev-parse --show-toplevel 2>/dev/null || echo .)"
              ${pkgs.nix}/bin/nix eval --json --file ./gen-catalog.nix > catalog.json
              echo "Wrote catalog.json"
            '');
          };

          # `nix run .#audit -- --env wifi` (or via `rfswift nix audit`): the
          # security / vulnerability / supply-chain audit. It runs against the
          # flake source in the store (RFSWIFT_AUDIT_FLAKE) and writes reports to
          # the caller's working directory, so it works from a published flake
          # too. jq/coreutils/etc. come from this pin; `nix` stays the host's (so
          # the user's substituters/caches apply), hence PATH is prepended, not
          # replaced. The scanners themselves are fetched by the script.
          audit = {
            type = "app";
            program = toString (pkgs.writeShellScript "rfswift-audit" ''
              export PATH=${lib.makeBinPath [ pkgs.jq pkgs.coreutils pkgs.gnugrep pkgs.gnused pkgs.gawk pkgs.bash ]}:$PATH
              export RFSWIFT_AUDIT_FLAKE=${self}
              exec ${pkgs.bash}/bin/bash ${self}/scripts/security-audit.sh "$@"
            '');
          };
        });

      formatter = forAllSystems (system: (pkgsFor system).nixpkgs-fmt);
    };
}
