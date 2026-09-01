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
      rawEnvironments = import ./environments.nix;

      # Baseline developer tools available in every RF Swift environment.
      # Keep these centralized so new environments inherit them automatically.
      # Keep synchronized with gen-catalog.nix so CLI/GUI metadata matches.
      commonPackages = [ "python3" "uv" "go" ];
      environments = nixpkgs.lib.mapAttrs (_: env: env // {
        packages = nixpkgs.lib.unique (commonPackages ++ env.packages);
      }) rawEnvironments;

      forAllSystems = f: nixpkgs.lib.genAttrs systems (system: f system);

      # On macOS, python3Packages.pyqt6 pulls qtwebengine via its `withPdf`
      # default. qtwebengine is not cached for aarch64-darwin and its source
      # build segfaults (in patchShebangs over the Chromium tree), which makes
      # every Qt-GUI Python tool - pyqtgraph, and therefore GNU Radio's
      # gnuradio-companion - impossible to build on macOS. pyqtgraph/GNU Radio
      # do not use QtPdf/QtWebEngine, so drop it on Darwin. Linux keeps the full
      # pyqt6 (qtwebengine is cached upstream there).
      pyqtNoWebengineOverlay = final: prev:
        prev.lib.optionalAttrs prev.stdenv.hostPlatform.isDarwin {
          pythonPackagesExtensions = (prev.pythonPackagesExtensions or [ ]) ++ [
            (pyfinal: pyprev: {
              pyqt6 = pyprev.pyqt6.override { withPdf = false; };
              # crccheck is pure Python, but nixpkgs marks its meta.platforms
              # linux-only. That wrongly drops `cantools` (and the automotive
              # env's DBC tooling) on macOS, even though CAN over USB adapters
              # (python-can's slcan/gs_usb/pcan backends) works fine there.
              # Widen it so cantools resolves on Darwin.
              crccheck = pyprev.crccheck.overrideAttrs (o: {
                meta = (o.meta or { }) // { platforms = prev.lib.platforms.unix; };
              });
              # meshtastic's runtime deps are all cross-platform (it declares
              # aarch64-darwin itself), but its test inputs pull pytap2, a
              # Linux-only TUN/TAP binding. Merely evaluating that throws
              # "not available on the requested hostPlatform", which takes the
              # whole sdr_full environment down on macOS. Skip the tests there.
              meshtastic = pyprev.meshtastic.overridePythonAttrs (o: {
                doCheck = false;
                nativeCheckInputs = [ ];
                checkInputs = [ ];
              });
            })
          ];
          # nixpkgs adds QtWebEngine unconditionally, although Cutter 2.5.0
          # neither finds nor links it (the source only prepares OpenGL sharing
          # for third-party plugins that may choose to use WebEngine). Keeping
          # the base application WebEngine-free avoids an uncached Chromium
          # build on Darwin without removing Cutter from the environment.
          cutter = prev.cutter.overrideAttrs (old: {
            buildInputs = builtins.filter
              (input: input != prev.qt6.qtwebengine)
              (old.buildInputs or [ ]);
          });
          # trunk-recorder 5.2.1's bundled op25 imbe_vocoder does not compile
          # against boost 1.89 with the Apple clang on this pin (in-class
          # initializer for a static data member is not a constant expression).
          # It builds fine on Linux; mark it linux-only so resolvePkg drops it on
          # Darwin instead of breaking the whole sdr_full environment build.
          trunk-recorder = prev.trunk-recorder.overrideAttrs (old: {
            meta = (old.meta or { }) // { platforms = prev.lib.platforms.linux; };
          });
        };

      # Python dependencies whose upstream test suites fail nondeterministically
      # on this nixpkgs pin - timing- or calendar-sensitive checks that break the
      # build depending on the runner and the date, not on our code. Skip only the
      # offending checks so these deps stop taking whole environments down. Applies
      # on every platform.
      flakyPyTestsOverlay = final: prev: {
        # arrow-cpp runs its gtest unittest suite as an installCheck. One of the
        # ~99 tests flakes on this pin (seen failing in one aarch64 cache run,
        # passing in another), which takes pyarrow - and the whole data-science
        # stack that dask/pandas/databricks pull in - down with it. It is a
        # consumed C++ dep, not our code, so drop the install check like the
        # Python suites below.
        arrow-cpp = prev.arrow-cpp.overrideAttrs (_: { doInstallCheck = false; });

        pythonPackagesExtensions = (prev.pythonPackagesExtensions or [ ]) ++ [
          (pyfinal: pyprev: {
            # date-/DST-sensitive scheduler tests plus a timing-sensitive result
            # hook (e.g. `assert date(2026,10,31) == date(2026,10,30)`); django-q2
            # comes in via mobsf (android). The whole suite is unreliable here.
            django-q2 = pyprev.django-q2.overridePythonAttrs (_: { doCheck = false; });
            # anyio's async suite has several timing-sensitive checks that race
            # under CI load and fail nondeterministically. It started with
            # test_acquire_cancelled (a CapacityLimiter "second borrower failed to
            # acquire the limiter" race), but disabling that one just moved the
            # failure to other checks that now flake on different Python versions
            # build-to-build. anyio is a pinned nixpkgs dep we consume (it
            # underpins the httpx/jupyter stack pulled into many environments),
            # not code we develop, so skip the whole check phase like django-q2.
            anyio = pyprev.anyio.overridePythonAttrs (_: { doCheck = false; });
            # The nixpkgs pin now defaults to CPython 3.14, on which several
            # large upstream test suites flake or trip a single 3.14-specific
            # assertion and take whole environments down in the cache build.
            # These are consumed deps, not our code, and each passes the vast
            # majority of its suite (django's full 18k-test run and aiohttp's
            # ~4840 checks pass locally here; CI shows a lone nondeterministic
            # failure). Skip only their check phases, same as anyio/django-q2.
            #
            #   aiohttp        one flaky websocket-pipelining check ("comparison
            #                  failed") that fails in ~1 of N cache runs.
            #   django         one nondeterministic check in the 18168-test suite
            #                  (passes in full locally; flakes under CI load).
            #                  Pulled in via mobsf, spiderfoot, and others.
            #   jupyter-server one 3.14 check failure (942 pass); jupyter is in
            #                  sdr_light/telecom/reversing and more.
            #   httpx2/httpcore2  the httpx 2.x pre-release, one failing check
            #                  each; underpins the fastapi/starlette/respx stack.
            aiohttp = pyprev.aiohttp.overridePythonAttrs (_: { doCheck = false; });
            django = pyprev.django.overridePythonAttrs (_: { doCheck = false; });
            jupyter-server = pyprev.jupyter-server.overridePythonAttrs (_: { doCheck = false; });
            # twisted runs its full 11k-test trial suite in checkPhase. Two TCP
            # connection-abort checks (test_fullWriteBuffer on the asyncio/select
            # reactors) raise TestTimeoutError "reactor still running after 120
            # seconds" - a timing-sensitive flake that trips under load on a busy
            # runner, not our code. It is a consumed dep (bumble/bleak/pyee pull
            # it into the bluetooth environment), so skip its check like the rest.
            twisted = pyprev.twisted.overridePythonAttrs (_: { doCheck = false; });
            # pytest-benchmark's own test suite runs live microbenchmarks
            # (time.perf_counter calibration loops with a max_time budget). On a
            # loaded or shared builder the timing never stabilizes and the
            # pytestCheckPhase hangs indefinitely (observed wedging an
            # aarch64-linux build for hours at ~21%). Benchmark timings are not a
            # correctness signal for a consumed dep, so skip its check phase.
            pytest-benchmark = pyprev.pytest-benchmark.overridePythonAttrs (_: { doCheck = false; });
            # watchfiles' Rust-backed test suite has a filesystem-watch check
            # (test_ignore_permission_denied) that trips a 10s pytest-timeout under
            # container/emulation load and on runners where "/" is watchable - a
            # timing/environment flake, not our code (150 pass, 1 flakes). It builds
            # from source on aarch64-linux (uncached CPython 3.14 pin) and comes in
            # via fastapi/uvicorn across several environments. Skip its check phase.
            watchfiles = pyprev.watchfiles.overridePythonAttrs (_: { doCheck = false; });
            # python-socks' test suite (test_proxy_sync_v2/test_resolvers, 429
            # cases) requires a live local SOCKS/HTTP proxy server on ::1:7780 -
            # the Nix build sandbox has no network, so every case errors with
            # "proxy server has not available ... in 10 seconds". Not our code; it
            # builds from source on aarch64-linux (uncached 3.14 pin) and comes in
            # via aiohttp-socks -> maigret (osint) and other tooling. Skip its checks.
            python-socks = pyprev.python-socks.overridePythonAttrs (_: { doCheck = false; });
            # rich flakes one check (test_console.py::test_brokenpipeerror, an
            # assert 0 == 1 over SIGPIPE/EPIPE handling) out of ~956 when built
            # from source on the CPython 3.14 pin - environment-sensitive, not our
            # code. rich is an extremely common transitive dep (angr/reversing and
            # many CLIs), so skip its check phase like the rest.
            rich = pyprev.rich.overridePythonAttrs (_: { doCheck = false; });
            # psycopg's test suite spins up a real PostgreSQL server and connects
            # over a unix socket; in the Nix sandbox that connection fails
            # ("connection to server on socket .../.s.PGSQL.5432 failed"), aborting
            # the whole run. Infrastructure the sandbox can't provide, not our code;
            # it builds from source on aarch64-linux and arrives via a data-science
            # chain (pytest-postgresql -> sqlframe -> plotly) in mobsf/android. Skip.
            # psycopg: doCheck=false skips the PostgreSQL test suite, but it then
            # trips pythonImportsCheckPhase importing psycopg_pool (a separate
            # distribution not in this build's closure), so drop that check too.
            psycopg = pyprev.psycopg.overridePythonAttrs (_: { doCheck = false; pythonImportsCheck = [ ]; });
            # plumbum: test_nohup.py::test_closed_filehandles hangs to a 300s
            # pytest-timeout in the sandbox (nohup/filehandle process timing);
            # 484 pass, 1 flakes. Consumed via rpyc -> angr (reversing).
            plumbum = pyprev.plumbum.overridePythonAttrs (_: { doCheck = false; });
            # prance: test_util_url asserts file:///etc/group, but the Nix sandbox's
            # /etc is a symlink into /nix/store, so the resolved URL differs (2 of
            # ~150). Sandbox path artifact; comes in via py5sig (telecom).
            prance = pyprev.prance.overridePythonAttrs (_: { doCheck = false; });
            # cmd2's test_path_completion_complete_user does ~<user> tilde
            # expansion for the current user; the Nix sandbox build user
            # (nixbld*) has no home dir, so completion returns [] and the assert
            # fails (1 of ~946). Sandbox artefact, not our code; builds from source
            # on aarch64-linux and comes in via pysim (telecom envs). Skip its check.
            cmd2 = pyprev.cmd2.overridePythonAttrs (_: { doCheck = false; });
          }
          # httpx2/httpcore2 are the httpx 2.x pre-release attrs; guard with
          # optionalAttrs so a later pin that renames or drops them still evals.
          // lib.optionalAttrs (pyprev ? httpx2) {
            httpx2 = pyprev.httpx2.overridePythonAttrs (_: { doCheck = false; });
          }
          // lib.optionalAttrs (pyprev ? httpcore2) {
            httpcore2 = pyprev.httpcore2.overridePythonAttrs (_: { doCheck = false; });
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
        overlays = [ pyqtNoWebengineOverlay flakyPyTestsOverlay ];
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
        in
        if available && forced.success
        then t.value
        else null;

      resolveEnv = system: env:
        let
          pkgs = pkgsFor system;
          custom = customFor system;
          prerequisites = env.prerequisites or [ ];
          declared = env.packages;
          resolved = assert lib.assertMsg
            (lib.all (name: builtins.elem name declared) prerequisites)
            "RF-Swift-nix: every prerequisite must also be listed in packages";
            map (name: { inherit name; drv = resolvePkg pkgs custom name; }) declared;
          present = builtins.filter (x: x.drv != null) resolved;
          absent = builtins.filter (x: x.drv == null) resolved;
          note = lib.optionalString (absent != [ ])
            (builtins.trace
              "RF-Swift-nix: ${builtins.toString (builtins.length absent)} package(s) unavailable on ${system}: ${lib.concatMapStringsSep ", " (x: x.name) absent}"
              "");
        in
        {
          drvs = map (x: x.drv) present;
          absent = map (x: x.name) absent;
          _note = note;
        };

      mkShellFor = system: name: env:
        let
          pkgs = pkgsFor system;
          r = resolveEnv system env;
        in
        pkgs.mkShell {
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
          # GUI tools built by nixpkgs only find GPU drivers on NixOS. Ship the
          # Mesa runtime (pkgs/rfswift-gl.nix) in every Linux environment so the
          # RF Swift engine can enable it on any other distribution.
          glRuntime = lib.optional pkgs.stdenv.hostPlatform.isLinux (customFor system).rfswift-gl;
        in
        pkgs.buildEnv {
          name = "rfswift-${name}";
          paths = r.drvs ++ glRuntime;
          ignoreCollisions = true;
        };

      # A separately addressable prerequisite closure used by the RF Swift CLI
      # to realise runtime libraries/device plugins before user applications.
      mkPrereqFor = system: name: env:
        let
          pkgs = pkgsFor system;
          custom = customFor system;
          names = env.prerequisites or [ ];
          resolved = map (n: resolvePkg pkgs custom n) names;
        in
        pkgs.buildEnv {
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
        // (lib.mapAttrs'
          (name: env:
            lib.nameValuePair "${name}-prerequisites" (mkPrereqFor system name env))
          (lib.filterAttrs (_: env: (env.prerequisites or [ ]) != [ ]) environments))
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
        let
          base = import nixpkgs {
            inherit system;
            config = {
              allowUnfree = true;
              android_sdk.accept_license = true;
            };
            overlays = [ self.overlays.default pyqtNoWebengineOverlay flakyPyTestsOverlay ];
          };
          # The reusable overlay cannot carry the separate nixpkgs-py310 input.
          # Merge customFor here so user-facing names such as `mirage` and
          # `bluing` resolve for `rfswift nix install`, which installs from
          # legacyPackages.<system>.<catalog-name>.
        in
        base // customFor system);

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

          # Unified maintainer interface for a checkout:
          # `nix run .#maintain -- check <package>`.
          maintain = {
            type = "app";
            program = toString (pkgs.writeShellScript "rfswift-maintain" ''
              export PATH=${lib.makeBinPath [ pkgs.bash pkgs.coreutils pkgs.curl pkgs.git pkgs.jq pkgs.ripgrep pkgs.gnused ]}:$PATH
              export RFSWIFT_MAINTENANCE_ROOT="$PWD"
              exec ${pkgs.bash}/bin/bash ${self}/scripts/package-maintenance.sh "$@"
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
