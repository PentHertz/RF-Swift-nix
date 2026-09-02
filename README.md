# ❄️ RF-Swift-nix

Current development version: **v1.0.0-dev**.

Reproducible RF, hardware and security tool environments for [RF Swift](https://github.com/PentHertz/RF-Swift), powered by the Nix package manager.

This is RF Swift's offensive Nix repo: a curated catalog of RF, hardware and offensive-security environments (Active Directory, Wi-Fi, RFID/NFC, Bluetooth, SDR, reversing, automotive, OSINT, Android and more). Use it standalone with plain Nix, or drive it through RF Swift for the full experience: automatic hardware access, OpenGL on non-NixOS hosts, udev rules, lazy on-demand builds and the shared binary cache.

This repository is to the `nix` engine what [RF-Swift-images](https://github.com/PentHertz/RF-Swift-images) is to the Docker engine: it holds the definitions of every environment ("image") and the packaging for the tools that go in them. The RF Swift binary reads `catalog.json` from here (or a pinned release of it) to know what environments exist, and evaluates this flake to build them.

## Why a Nix engine

Docker gives you an isolated image. Nix gives you a reproducible set of tools installed straight onto the host, with no daemon and no container. `rfswift run --engine nix -i sdr_light -n mysdr` builds the exact same closure everywhere, pins it so it survives garbage collection, and drops you into a shell with the tools on `PATH`. USB and audio just work because there is no container boundary to cross.

## Layout

```
environments.nix     the catalog as pure data: image -> package list (single source of truth)
gen-catalog.nix      turns environments.nix into catalog.json
catalog.json         machine-readable index the RF Swift binary reads (generated)
flake.nix            builds devShells / profiles from environments.nix + pkgs/
pkgs/                RF Swift's own derivations (source builds, forks, vendor blobs)
```

The current implementation status, evidence levels, known gaps, and RF Swift
binary improvement backlog are maintained in
[`docs/verification-audit.md`](docs/verification-audit.md).

GitHub Actions, binary cache publishing, branch protection, and release hand-off are
documented in [`docs/ci-cd.md`](docs/ci-cd.md).

Cache population is split into independent amd64, native arm64, and
QEMU-backed riscv64 workflows. Each uploads raw logs plus JSON/Markdown problem
reports, and one architecture failing cannot stop either of the others.

## ❄️ Use it directly with Nix

```bash
# List what the flake exposes
nix flake show

# Enter an environment as a dev shell
nix develop github:PentHertz/RF-Swift-nix#sdr_light

# Or install its whole tool closure into a profile
nix profile install github:PentHertz/RF-Swift-nix#rfid

# Build a single RF Swift tool
nix build github:PentHertz/RF-Swift-nix#pkg-readsb
```

Or consume it as a flake input from your own `flake.nix`:

```nix
{
  inputs.rfswift-nix.url = "github:PentHertz/RF-Swift-nix";

  outputs = { self, nixpkgs, rfswift-nix, ... }:
    let system = "x86_64-linux"; in {
      # pull an environment's dev shell straight into yours
      devShells.${system}.default = rfswift-nix.devShells.${system}.sdr_light;
      # or expose a single RF Swift tool as a package
      packages.${system}.readsb = rfswift-nix.packages.${system}.pkg-readsb;
    };
}
```

Or, the RF Swift way:

```bash
rfswift run --engine nix -i sdr_light -n mysdr        # build the whole set once
rfswift run --engine nix -i sdr_light -n mysdr --lazy # or build each tool on first call
rfswift nix run sdr_light gqrx                        # or just run one tool on demand
rfswift nix catalog                                   # browse environments
rfswift nix list                                      # your created environments
```

In a lazy SDR environment, run `gnuradio-companion`. Its first invocation
realizes the `gnuradio-rfswift` closure, which already contains all RF Swift OOT
modules; they are not fetched separately from inside GRC. The initial launch can
therefore be substantial, while later launches reuse the same Nix store closure.

## Eager vs on-demand, and the binary cache

Creating an environment eagerly builds its whole tool closure once; `--lazy` builds each tool the first time it is called. Either way, "build" is mostly "download a prebuilt binary from a cache", not "compile". Standard nixpkgs tools come prebuilt from `cache.nixos.org`; only tools not in a cache compile locally, which here is the handful of derivations in `pkgs/`. The architecture-specific cache workflows build the environments and push them to the PentHertz binary cache, so once your machine is pointed at it, even those download prebuilt. Client setup (token, `nix.conf`, verification) is in [`docs/binary-cache.md`](docs/binary-cache.md); the CI side is in [`docs/ci-cd.md`](docs/ci-cd.md).

## OpenGL and hardware access on hosts that are not NixOS

nixpkgs GUI tools (SDR++, gqrx, inspectrum, GNU Radio Companion, ...) link against nixpkgs' Mesa and libglvnd, which find GPU drivers only where NixOS installs them (`/run/opengl-driver`). Every Linux environment therefore ships `rfswift-gl` ([`pkgs/rfswift-gl.nix`](pkgs/rfswift-gl.nix)), the nixGL approach in package form: `share/rfswift/gl.env` lists the variables that point the loaders at Mesa's drivers from this pin, and `bin/rfswift-gl <program>` applies them. The RF Swift engine exports them automatically on non-NixOS hosts; by hand:

    nix run .#rfswift-gl -- sdrpp

The proprietary NVIDIA driver needs its own user-space libraries, matching the host's kernel module, so `rfswift-gl-nvidia` is built impurely (`RFSWIFT_NVIDIA_VERSION=<version from /proc/driver/nvidia/version> nix build --impure .#pkg-rfswift-gl-nvidia`), with Mesa kept behind it for hybrid GPUs. The engine does this once per driver version.

Intel, AMD, VMware/virtio and every other open kernel driver are served by Mesa from this pin; on macOS nixpkgs programs use Apple's OpenGL/Metal directly and need nothing. Both runtime packages ship `rfswift-gl-probe`, which creates an OpenGL context without a window and prints the driver that answered (`nix run .#rfswift-gl -- rfswift-gl-probe`); `rfswift nix gl --check` runs it for an environment.

SDR++ (`sdrpp-hydrasdr`) is built with every device source RF Swift's images ship, on the architectures their libraries exist for: HydraSDR, Harogic (x86_64/aarch64 Linux), SignalHound BB60 (Linux and Apple Silicon) and Deepace KC908 (x86_64 Linux). SDR++, gqrx (via the PentHertz gr-osmosdr), SigDigger, SatDump and rtl_433 all link RF Swift's own SoapySDR plugin set (nixpkgs modules plus SoapyHydraSDR, SoapyRFNM, SoapyXTRX, LiteX M2SDR, uSDR), so each of them sees the same radios; URH compiles its native backends against the same libraries and LuaRadio finds them on its library path.

Native tools run as the user, so SDR/RFID hardware needs the udev rules the packages ship (`lib/udev/rules.d`, `etc/udev/rules.d`) installed on the host: `rfswift nix udev <env>` collects them from the environment and installs them.

## 📡 Environments

Run `rfswift nix catalog` or `nix eval .#catalog` for the live list. At a glance:

| Environment | What it gives you |
|-------------|-------------------|
| `sdr_light` | GNU Radio, GQRX, SDR++, URH, inspectrum, rtl_433, dump1090/readsb, plus the full SDR driver layer |
| `sdr_full`  | `sdr_light` plus SDRangel, SatDump, SigDigger, GNU Radio OOT modules and an ML stack |
| `rfid`      | Proxmark3, libnfc, MIFARE crackers, NFC utilities |
| `wifi`      | aircrack-ng, hcxtools, WPS/WPA3 attacks, on the network toolkit |
| `bluetooth` | BlueZ, Ubertooth, Python BLE tooling |
| `network`   | nmap, Wireshark, Metasploit, bettercap, Kismet, hashcat/john, sqlmap |
| `reversing` | Ghidra, rizin/Cutter, radare2, binwalk, angr, AFL++, semgrep, ImHex |
| `hardware`  | avrdude, sigrok/PulseView, OpenOCD, flashrom, openFPGALoader, esptool |
| `automotive`| can-utils, SavvyCAN, python-can |
| `osint`     | theHarvester, sherlock, recon-ng, subfinder, exiftool |
| `android`   | adb/fastboot, apktool, frida, androguard, scrcpy, jadx |
| `ad`        | impacket, NetExec, kerbrute, Samba/LDAP/Kerberos clients |

## Adding or changing an environment

1. Edit `environments.nix` (add a package attribute path, or a new environment entry).
2. Run `nix run .#gen-catalog` to refresh `catalog.json`.
3. `nix develop .#<env>` to try it.

Before submitting a change, run `./tests/verify.sh`. It regenerates and compares
the catalog, forces every environment and custom package derivation, and (when
the RF-Swift repository is checked out beside this one) checks that the CLI's
embedded catalog is synchronized. CI additionally builds every environment
closure; those builds are release gates rather than allowed failures.
To reproduce CI's build-and-command check for one closure locally, run
`./tests/smoke-environment.sh automotive` (or another environment name).

A package string is an attribute path into `pkgs` (for example `gnuradioPackages.osmosdr`), or the name of one of RF Swift's own derivations in `pkgs/`, which take priority. Anything unavailable on a given platform is dropped at evaluation with a trace, so one missing tool never breaks the whole shell.

## 📦 Packaging tools (`pkgs/`)

Most RF Swift tools are in nixpkgs. The rest live in `pkgs/`, in three flavours: plain source builds, forks (built by overriding a nixpkgs source), and proprietary vendor binaries (`autoPatchelfHook`). New source derivations ship with a placeholder hash you pin on the first build. See [`pkgs/README.md`](pkgs/README.md).

## License

Tool licenses are their own. The packaging in this repository follows RF Swift's license.
