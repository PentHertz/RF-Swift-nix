# SDR device and application layers

RF Swift follows the image build order in Nix as two explicit layers:

1. Runtime device libraries, firmware, SoapySDR modules and vendor SDKs.
2. GNU Radio and end-user SDR applications.

`sdr_light` uses `gnuradio-rfswift-light` (GNU Radio plus the PentHertz
`gr-osmosdr` common source/sink module). `sdr_full` uses
`gnuradio-rfswift`, which adds the extended OOT batches installed by
`RF-Swift-images/Dockerfiles/SDR/sdr_full.docker`. Telecom uses the light set
because its Docker image inherits from `sdr_light`.

In eager or pure mode, RF Swift builds `<environment>-prerequisites` before the
complete environment. In lazy mode, the first program shim builds that
prerequisite closure before launching the requested program. A prerequisite is
also a real Nix dependency of its own derivation where it is needed at compile
or link time; the layer additionally covers separately discovered runtime
plugins.

The common layer includes RTL-SDR, HackRF, Airspy/AirspyHF, LimeSDR, UHD/USRP,
bladeRF, PlutoSDR (libiio/libad9361 plus SoapyPlutoSDR), HydraSDR, osmo-fl2k,
LibreSDR firmware and SoapyRemote. Signal Hound support includes the BB60D and
the other BB60, SM200, SP145, SA and VSG60 families through the vendor SDK; on
x86_64, Spike and the VSG60 controller are included too. Harogic uses the HTRA
SDK and SAStudio.

Both SDR profiles also include NanoVNA Saver, NanoVNA-QT, LibreVNA, xnec2c and
the KC908/KCSDI package. Image-only calibration helpers are kept in the
catalog's explicit `missing` list until their Nix packages have been built and
tested.

SDRplay remains a documented gap: the API derivation in the pinned nixpkgs
revision currently points to an upstream 3.15.1 download that returns HTTP 404,
so it is not advertised as working.

## LibreSDR B210/B220 FPGA selection

The `sdr_light` and `sdr_full` device layers include both pinned LibreSDR FPGA
images and `libresdr_swapfpga`. Nix store paths are immutable, so the helper
creates a writable UHD image override below
`$XDG_DATA_HOME/rfswift/libresdr/uhd-images` (or
`~/.local/share/rfswift/libresdr/uhd-images`) instead of overwriting the UHD
package.

```console
libresdr_swapfpga b210
libresdr_swapfpga b220
libresdr_swapfpga status
libresdr_swapfpga restore
```

The easiest way to select an image and run a UHD-based program with the correct
`UHD_IMAGES_DIR` in one command is:

```console
libresdr_swapfpga run b210 uhd_find_devices
libresdr_swapfpga run b220 gnuradio-companion
```

For the current shell, export the generated environment assignment:

```console
eval "$(libresdr_swapfpga env)"
```

The environment catalog's `missing` field is the ground-truth gap list. A
Docker-only driver or OOT module remains named there until its Nix derivation
and runtime loading have been verified; it is never silently reported as
included.
