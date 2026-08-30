# voipire (CR-DMcDonald/voipire): a Rust RTP/VoIP eavesdropping tool. Upstream
# ships no Cargo.lock, so a lock generated for this exact revision is pinned
# beside this file and fed to buildRustPackage (cargoLock.lockFile), which
# vendors the dependencies deterministically. Matches RF-Swift-images'
# voipire_soft_install (cargo build --release).
{ lib, rustPlatform, fetchFromGitHub }:

rustPlatform.buildRustPackage {
  pname = "voipire";
  version = "unstable-2026-08-30";

  src = fetchFromGitHub {
    owner = "CR-DMcDonald";
    repo = "voipire";
    rev = "821884f233f22f9adc390d4f199acd1c6ed05602";
    hash = "sha256-XsJff8JQQASAyp0sZGbIStD7STdNB9wpDz6Z+l5xdMs=";
  };

  cargoLock.lockFile = ./voipire-Cargo.lock;

  meta = {
    description = "RTP/VoIP eavesdropping tool (Rust)";
    homepage = "https://github.com/CR-DMcDonald/voipire";
    license = lib.licenses.mit;
    platforms = lib.platforms.unix;
    mainProgram = "voipire";
  };
}
