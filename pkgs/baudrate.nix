# baudrate: RF Swift's own serial baud-rate finder (cycles common rates on a
# port and flags mostly-printable output). The script is copied verbatim from
# RF-Swift-images' serial_tools_install (scripts/hardware.sh), which writes it
# inline to /usr/local/bin/baudrate; only the shebang changes (writePython3Bin).
{ lib, writers, python3Packages }:

(writers.writePython3Bin "baudrate" {
  libraries = [ python3Packages.pyserial ];
  # Upstream style (one-line imports, long lines) kept verbatim.
  flakeIgnore = [ "E401" "E501" ];
} ''
  """Cycle through common baud rates on a serial port and show what comes in.
  Usage: baudrate /dev/ttyUSB0 [-t SECONDS]   (Ctrl-C to stop; 'ok' = mostly printable)"""
  import argparse, sys, time
  import serial

  RATES = [115200, 57600, 38400, 19200, 9600, 4800, 2400, 1200, 230400, 460800, 921600]
  ap = argparse.ArgumentParser()
  ap.add_argument("port")
  ap.add_argument("-t", type=float, default=2.0, help="seconds to listen per rate (default 2)")
  a = ap.parse_args()
  try:
      for rate in RATES:
          with serial.Serial(a.port, rate, timeout=0.2) as s:
              print(f"\n=== {rate} baud ===", flush=True)
              end = time.time() + a.t
              while time.time() < end:
                  data = s.read(256)
                  if data:
                      printable = sum(32 <= b < 127 or b in (9, 10, 13) for b in data) / len(data)
                      sys.stdout.write(("ok " if printable > 0.9 else "?? ") + data.decode("ascii", "replace"))
                      sys.stdout.flush()
  except KeyboardInterrupt:
      pass
'').overrideAttrs (old: {
  pname = "baudrate";
  version = "1.1.2"; # RF-Swift-images release the script was taken from
  meta = (old.meta or { }) // {
    description = "Serial port baud-rate finder (RF Swift helper)";
    homepage = "https://github.com/PentHertz/RF-Swift-images";
    license = lib.licenses.gpl3Only;
    platforms = lib.platforms.unix;
    mainProgram = "baudrate";
  };
})
