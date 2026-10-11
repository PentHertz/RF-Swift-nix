# ChipWhisperer (newaetech/chipwhisperer): NewAE's Python API for side-channel
# power analysis and fault injection (capture/glitch with CW-Lite, CW-Pro,
# CW-Husky, CW-Nano, target programming, CW305 bitstreams, trace analysis).
# Matches RF-Swift-images' chipwhisperer_install (pip3 install chipwhisperer).
#
# nixpkgs' python3Packages.chipwhisperer (5.7.0) is marked broken: 5.x and the
# 6.0.0 on PyPI pin numpy<=1.26.4, which nixpkgs no longer ships (nor does
# NumPy 1.26 support Python 3.14). Upstream's NumPy 2 line is the
# `sca101_release` tag (still version 6.0.0), whose lock file matches this pin
# (numpy 2.5.2, numba 0.67), so it is built from that tag.
#
# Only software/ is checked out (the package with its bundled FPGA bitstreams
# and MCU firmware, ~50 MB) plus the top-level files (pyproject, licence, udev
# rule): the repository also carries hardware designs, victim firmware and docs.
{ lib, buildPythonPackage, fetchFromGitHub, python
, setuptools, setuptools-scm
, numba, numpy, pyserial, ecpy, cython, tqdm, libusb1, zarr, crc, pycryptodome
}:

buildPythonPackage {
  pname = "chipwhisperer";
  version = "6.0.0-unstable-2026-08-25";
  pyproject = true;

  src = fetchFromGitHub {
    owner = "newaetech";
    repo = "chipwhisperer";
    rev = "b382039dd7ee653ec0797f38b0410d06e145ea39"; # tag sca101_release
    sparseCheckout = [ "software" ];
    hash = "sha256-8Elyn+CwqkOS0Bc5rAvzA8rxnFcUsVts6N6/ft30sjk=";
  };

  # The bitstreams/firmware are package data, which upstream ships through
  # include-package-data and setuptools-scm's git file finder. With no .git in
  # the source that finder lists nothing and they would be silently dropped,
  # so name them explicitly.
  postPatch = ''
    cat > MANIFEST.in <<'EOF'
    graft software/chipwhisperer
    global-exclude *.py[cod] __pycache__
    EOF
  '';

  build-system = [ setuptools setuptools-scm ];

  dependencies = [
    numba
    pyserial
    numpy
    ecpy
    cython
    tqdm
    libusb1
    zarr
    crc
    pycryptodome
  ];

  postInstall = ''
    # Fail the build rather than ship an API that cannot program its devices.
    fw=$out/${python.sitePackages}/chipwhisperer/hardware/firmware
    for f in cw1200/bitstream.zip cw1200/mcufw.bin cw305/AES_100t.bit; do
      test -e "$fw/$f" || { echo "chipwhisperer: missing package data $f" >&2; exit 1; }
    done

    # Upstream's 50-newae.rules grants a `chipwhisperer` group no host has; use
    # RF Swift's convention instead (local user via uaccess, permissive mode as
    # a fallback) for NewAE devices, their serial ports and the SAM-BA
    # bootloader, keeping upstream's /dev symlinks.
    mkdir -p $out/lib/udev/rules.d
    cat > $out/lib/udev/rules.d/50-newae.rules <<'RULES'
    # NewAE ChipWhisperer - installed by RF Swift (nix engine)
    SUBSYSTEMS=="usb", ATTRS{idVendor}=="2b3e", MODE="0666", TAG+="uaccess"
    SUBSYSTEM=="tty", ATTRS{idVendor}=="2b3e", MODE="0666", TAG+="uaccess", SYMLINK+="cw_serial%n"
    SUBSYSTEM=="tty", ATTRS{idVendor}=="03eb", ATTRS{idProduct}=="6124", MODE="0666", TAG+="uaccess", SYMLINK+="cw_bootloader%n"
    RULES
  '';

  # The test suite lives outside software/ and almost entirely needs attached
  # hardware ("Could not find ChipWhisperer. Is it connected?").
  doCheck = false;
  pythonImportsCheck = [
    "chipwhisperer"
    "chipwhisperer.analyzer"
    "chipwhisperer.capture.scopes"
  ];

  meta = {
    description = "NewAE ChipWhisperer API: side-channel power analysis and fault injection";
    homepage = "https://github.com/newaetech/chipwhisperer";
    license = lib.licenses.asl20;
    platforms = lib.platforms.unix;
  };
}
