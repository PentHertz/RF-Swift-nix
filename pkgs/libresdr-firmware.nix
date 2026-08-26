{ lib, fetchurl, runCommand, writeShellApplication, symlinkJoin, coreutils, uhd }:

let
  b210 = fetchurl {
    url = "https://github.com/FlUxIuS/libresdr-b2xx/releases/download/2024.1/libresdr_b210.bin";
    hash = "sha256-fw4ym0ck4NkZoGuZJKqjx3MFtvJQON7r1hcWV6x8ipk=";
  };
  b220 = fetchurl {
    url = "https://github.com/FlUxIuS/libresdr-b2xx/releases/download/2024.1/libresdr_b220.bin";
    hash = "sha256-cyKiqQUlIMilBkbnc71zWeaDzJvc8VnukGh1N1EkbOU=";
  };
  firmware = runCommand "libresdr-fpga-firmware-2024.1" { } ''
    install -Dm444 ${b210} $out/share/rfswift/libresdr/libresdr_b210.bin
    install -Dm444 ${b220} $out/share/rfswift/libresdr/libresdr_b220.bin
  '';
  switcher = writeShellApplication {
    name = "libresdr_swapfpga";
    runtimeInputs = [ coreutils ];
    text = ''
      state_root="''${XDG_DATA_HOME:-$HOME/.local/share}/rfswift/libresdr"
      image_dir="$state_root/uhd-images"
      target="$image_dir/usrp_b210_fpga.bin"
      original=${uhd}/share/uhd/images/usrp_b210_fpga.bin
      b210=${firmware}/share/rfswift/libresdr/libresdr_b210.bin
      b220=${firmware}/share/rfswift/libresdr/libresdr_b220.bin

      initialise() {
        mkdir -p "$image_dir"
        if [ ! -e "$state_root/usrp_b210_fpga_original.bin" ]; then
          install -m 0644 "$original" "$state_root/usrp_b210_fpga_original.bin"
        fi
      }
      select_image() {
        initialise
        case "$1" in
          b210) install -m 0644 "$b210" "$target" ;;
          b220) install -m 0644 "$b220" "$target" ;;
          original|restore) install -m 0644 "$state_root/usrp_b210_fpga_original.bin" "$target" ;;
          *) echo "usage: libresdr_swapfpga {b210|b220|restore|status|env|run}" >&2; return 2 ;;
        esac
        printf 'Selected %s FPGA image.\nUHD_IMAGES_DIR=%s\n' "$1" "$image_dir"
      }

      command="''${1:-}"
      case "$command" in
        b210|b220|original|restore) select_image "$command" ;;
        status)
          initialise
          if [ -e "$target" ]; then sha256sum "$target"; else echo "No FPGA selected"; fi
          printf 'UHD_IMAGES_DIR=%s\n' "$image_dir"
          ;;
        env)
          initialise
          printf 'export UHD_IMAGES_DIR=%q\n' "$image_dir"
          ;;
        run)
          mode="''${2:-}"; shift 2 || true
          [ "$#" -gt 0 ] || { echo "usage: libresdr_swapfpga run {b210|b220|original} COMMAND [ARGS...]" >&2; exit 2; }
          select_image "$mode" >/dev/null
          exec env UHD_IMAGES_DIR="$image_dir" "$@"
          ;;
        "")
          printf 'LibreSDR FPGA: 1) B210  2) B220  3) original  4) cancel\nChoice: '
          read -r choice
          case "$choice" in 1) select_image b210;; 2) select_image b220;; 3) select_image original;; *) exit 0;; esac
          ;;
        *) echo "usage: libresdr_swapfpga {b210|b220|restore|status|env|run}" >&2; exit 2 ;;
      esac
    '';
  };
in symlinkJoin {
  name = "libresdr-firmware-2024.1";
  paths = [ firmware switcher ];
  meta = {
    description = "LibreSDR B210/B220 FPGA images and safe per-user UHD switcher";
    homepage = "https://github.com/FlUxIuS/libresdr-b2xx";
    license = lib.licenses.unfreeRedistributableFirmware;
    platforms = lib.platforms.linux;
    mainProgram = "libresdr_swapfpga";
  };
}
