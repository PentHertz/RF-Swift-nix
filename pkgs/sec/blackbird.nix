# Blackbird (p1ngul1n0/blackbird, now antoniaci/blackbird): OSINT search for
# accounts by username or email (WhatsMyName lists). Matches RF-Swift-images'
# blackbird_soft_install, which runs blackbird.py from its checkout with a venv
# built from requirements.txt. (Shadows nixpkgs' unrelated, removed GTK theme
# of the same name.)
#
# Upstream resolves data/, assets/ and logs/ against the current directory and
# writes results/ next to its own sources, so it only works from a writable
# checkout. Here the checkout is read-only under share/ and the paths are
# patched so the tool runs from the caller's directory:
#   - bundled data (email list, site metadata, user agents), fonts and images
#     are read from share/blackbird;
#   - the downloaded WhatsMyName list, logs/blackbird.log and the AI key go to
#     $BLACKBIRD_STATE_DIR (default ${XDG_DATA_HOME:-~/.local/share}/blackbird);
#   - --csv/--pdf/--json/--dump output goes to ./results/ in the current
#     directory, and -uf/-ef file paths stay relative to it.
# .env (API_URL) is still loaded from share/; set INSTAGRAM_SESSION_ID in the
# environment instead of editing it.
{ lib, stdenvNoCC, fetchFromGitHub, makeWrapper, python3 }:

let
  pyEnv = python3.withPackages (ps: with ps; [
    aiohttp requests rich python-dotenv reportlab pillow chardet
  ]);
in
stdenvNoCC.mkDerivation {
  pname = "blackbird";
  version = "unstable-2026-10-17";

  src = fetchFromGitHub {
    owner = "antoniaci"; # github.com/p1ngul1n0/blackbird redirects here
    repo = "blackbird";
    rev = "c8329b2e83f20e3f74b218e68200389d838a6832";
    hash = "sha256-0EvU8tirERhg+oXOzOqkNtsXDXy36m+nu4t3xN/5IAo=";
  };

  nativeBuildInputs = [ makeWrapper ];
  dontBuild = true;

  postPatch = ''
    substituteInPlace src/config.py \
      --replace-fail 'import os' 'import os

    SHARE_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    STATE_DIR = os.environ.get("BLACKBIRD_STATE_DIR") or os.path.join(
        os.environ.get("XDG_DATA_HOME") or os.path.expanduser("~/.local/share"), "blackbird"
    )' \
      --replace-fail 'os.path.join(os.getcwd(), LIST_DIRECTORY, USERNAME_LIST_FILENAME)' \
                     'os.path.join(STATE_DIR, USERNAME_LIST_FILENAME)' \
      --replace-fail 'os.getcwd(), LIST_DIRECTORY' 'SHARE_DIR, LIST_DIRECTORY' \
      --replace-fail 'os.path.join(os.getcwd(), LOG_DIRECTORY, LOG_FILENAME)' \
                     'os.path.join(STATE_DIR, LOG_DIRECTORY, LOG_FILENAME)'

    substituteInPlace blackbird.py \
      --replace-fail '"logs/"' 'os.path.dirname(config.LOG_PATH)' \
      --replace-fail '"assets/text/splash.txt"' \
                     'os.path.join(config.SHARE_DIR, "assets", "text", "splash.txt")'

    substituteInPlace src/modules/export/pdf.py \
      --replace-fail 'os.getcwd()' 'config.SHARE_DIR'

    substituteInPlace src/modules/export/file_operations.py \
      --replace-fail 'os.path.dirname(__file__), "..", "..", "..", "results"' \
                     'os.getcwd(), "results"'

    substituteInPlace src/modules/ai/key_manager.py \
      --replace-fail 'PROJECT_ROOT / ".ai_key.json"' \
                     'Path(__import__("config").STATE_DIR) / ".ai_key.json"'
  '';

  installPhase = ''
    runHook preInstall
    mkdir -p $out/share/blackbird $out/bin
    cp -r blackbird.py src data assets .env $out/share/blackbird/
    makeWrapper ${pyEnv}/bin/python3 $out/bin/blackbird \
      --add-flags "$out/share/blackbird/blackbird.py"
    runHook postInstall
  '';

  meta = {
    description = "OSINT tool to search for accounts by username or email across sites";
    homepage = "https://github.com/p1ngul1n0/blackbird";
    license = lib.licenses.cc-by-nc-sa-40; # .github/LICENSE (non-commercial, so unfree in nixpkgs)
    platforms = lib.platforms.unix;
    mainProgram = "blackbird";
  };
}
