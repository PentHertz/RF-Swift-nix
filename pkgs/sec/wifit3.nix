# wifit3 (derv82): standalone USB Wi-Fi auditor TUI (Textual). It drives the
# adapters itself through user-space Python ports of the Linux drivers over
# PyUSB, with the vendor firmware bundled, so it needs neither aircrack-ng nor a
# monitor-mode kernel driver. Matches RF-Swift-images' wifit3_soft_install
# (pipx from git master, so this pins master rather than the v0.5.0 tag).
#
# The images skip it off x86_64/aarch64 because libusb-package ships wheels for
# those only; nixpkgs builds libusb-package from source and points it at its
# own libusb, so riscv64 and macOS work too.
#
# First START on a card (Linux) asks pkexec/sudo once to write
# /etc/udev/rules.d/60-wifit3-<chip>.rules and /etc/modprobe.d/wifit3-<chip>.conf
# on the host, keeping the kernel driver off that chipset; its Uninstall button
# removes them.
{ lib, python3Packages, fetchFromGitHub }:

python3Packages.buildPythonApplication {
  pname = "wifit3";
  version = "0.5.0-unstable-2026-10-18";
  pyproject = true;

  src = fetchFromGitHub {
    owner = "derv82";
    repo = "wifit3";
    rev = "5638cabbfbe80a8bfef1f545842dec383eb39225";
    hash = "sha256-DM/y6FPnEHZRTk+/f6FzVLgl2Xf74pn25Zr4jRGHSGY=";
  };

  # libwdi's wdi-simple.exe (WinUSB installer), 14 MB used by the Windows
  # setup path only.
  postPatch = ''
    rm -r src/wifit3/setup/bin/win-*
  '';

  build-system = [ python3Packages.hatchling ];
  dependencies = with python3Packages; [
    libusb-package
    platformdirs
    pyusb
    rich
    textual
  ];

  nativeCheckInputs = with python3Packages; [
    pytestCheckHook
    pytest-asyncio
    pytest-mock
  ];
  pythonImportsCheck = [ "wifit3" ];
  # The path picker lists $HOME among its roots and a test checks it exists.
  preCheck = ''
    export HOME=$TMPDIR
  '';
  # Checks the wdi-simple.exe removed above is bundled for the build machine's
  # architecture (x86_64 only; other architectures skip it).
  disabledTests = [ "test_wdi_simple_path_resolves_to_bundled_exe" ];

  # After the test suite, upstream's own headless self-test: loads libusb
  # through libusb-package, mounts every screen with Textual's test pilot and
  # checks the chip drivers are discoverable.
  postInstallCheck = ''
    $out/bin/wifit3 --smoke
  '';

  meta = {
    description = "Standalone USB Wi-Fi auditor with built-in user-space drivers";
    homepage = "https://github.com/derv82/wifit3";
    license = lib.licenses.gpl2Only;
    platforms = lib.platforms.linux ++ lib.platforms.darwin;
    mainProgram = "wifit3";
  };
}
