# wifite2 at kimocoder's master, which RF-Swift-images' wifite2_soft_install
# installs (pipx from git; derv82's original has been frozen since 2018).
# nixpkgs' recipe tracks kimocoder's 2.7.0 release; this keeps that recipe and
# its tool closure and moves the source forward.
#
#   * master builds with poetry-core and adds requests and rich; nixpkgs is a
#     little behind its floors (chardet 6 vs >=7.6, scapy 2.7.0 vs 2.7.1rc1,
#     setuptools 83 vs 84), which the test suite runs against.
#   * The evil-twin attack added since 2.7.0 drives hostapd, dnsmasq,
#     wpa_supplicant, ip and iptables; they join the tools on the wrapper's
#     PATH.
#   * pip leaves the bundled wordlist out, so the images copy it to
#     /usr/local/share/dict/wordlists, one of wifite's default search paths.
#     Here it is installed under $out/share/dict/wordlists and that path is
#     added to the search list, after the system ones. Likewise the OUI table
#     (vendor names in the target list): wifite reads
#     /usr/share/ieee-data/oui.txt or ./ieee-oui.txt, so the bundled copy
#     replaces the cwd fallback.
#   * John cracking picks wpapsk-opencl whenever john lists it, and nixpkgs'
#     john is built with OpenCL, so it always does - then cracks nothing when
#     no OpenCL device is reachable (nixpkgs' ICD loader only looks under
#     /run/opengl-driver, so on most non-NixOS hosts). It now takes the OpenCL
#     format only when `john --list=opencl-devices` shows a device, else wpapsk
#     on the CPU.
{ lib, wifite2, fetchFromGitHub, python3Packages
, hostapd, dnsmasq, wpa_supplicant, iproute2, iptables }:

let
  eviltwinTools = [ hostapd dnsmasq wpa_supplicant iproute2 iptables ];
in
wifite2.overridePythonAttrs (old: {
  version = "2.9.9-beta-unstable-2026-10-10";

  src = fetchFromGitHub {
    owner = "kimocoder";
    repo = "wifite2";
    rev = "1896bd59676ab498c0e828a0fa7513556d615218";
    hash = "sha256-GhbK1aLrR3/R/L2qFU9RFNL+xvLPs/ofrKq3EhnsScQ=";
  };

  # Debian's patches target 2.7.0's sources; of the tests they disabled, only
  # the aircrack-ng handshake check still fails (disabledTests below).
  patches = [ ];

  postPatch = (old.postPatch or "") + ''
    substituteInPlace wifite/config/defaults.py --replace-fail \
      "'/usr/local/share/dict/wordlists/',  # setup.py with prefix=/usr/local" \
      "'/usr/local/share/dict/wordlists/',  # setup.py with prefix=/usr/local
            '$out/share/dict/wordlists/',  # bundled with the Nix package"
    substituteInPlace wifite/config/manufacturers.py --replace-fail \
      "mfr_file = 'ieee-oui.txt'" "mfr_file = '$out/share/wifite2/ieee-oui.txt'"
    substituteInPlace wifite/tools/john.py --replace-fail \
      "if 'wpapsk-opencl' in combined:" \
      "if 'wpapsk-opencl' in combined and 'Device #' in subprocess.run(['john', '--list=opencl-devices'], capture_output=True, text=True, timeout=10).stdout:"
  '';

  build-system = [ python3Packages.poetry-core ];
  dependencies = with python3Packages; [ chardet requests rich scapy setuptools ];
  pythonRelaxDeps = [ "chardet" "scapy" "setuptools" ];

  propagatedBuildInputs = old.propagatedBuildInputs ++ eviltwinTools;

  # The recipe's own propagated tools are not on PATH while it is tested.
  nativeCheckInputs = old.nativeCheckInputs ++ eviltwinTools
    ++ [ python3Packages.pytest-timeout ];
  # john writes ~/.john before printing its version or formats.
  preCheck = (old.preCheck or "") + ''
    export HOME=$TMPDIR
  '';
  disabledTests = (old.disabledTests or [ ]) ++ [
    # aircrack-ng finds no handshake in the bundled capture (Debian disables it
    # in 2.7.0 too).
    "testHandshakeAircrack"
    # Expects "version N" in john's banner; jumbo-bleeding prints
    # "John the Ripper 1.9.0-jumbo-1+bleeding-...".
    "test_john_version_readable"
    # Its capture's key, "1234", is shorter than WPA's 8-character minimum,
    # which john's wpapsk format enforces, so no john can crack it.
    "test_crack_known_key_handshake"
  ];

  postInstall = (old.postInstall or "") + ''
    install -Dm644 -t $out/share/dict/wordlists wordlists/*.txt
    install -Dm644 ieee-oui.txt $out/share/wifite2/ieee-oui.txt
  '';
})
