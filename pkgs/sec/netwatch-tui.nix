# netwatch-tui: published Rust TUI (crates.io) for live network monitoring.
{ lib, rustPlatform, fetchCrate }:

rustPlatform.buildRustPackage rec {
  pname = "netwatch-tui";
  version = "0.29.2";

  src = fetchCrate {
    inherit pname version;
    hash = "sha256-E746zHDvCeufb5XDpkRJwXtpEWHTr4zD/Zi9eNCBdg4=";
  };

  cargoHash = "sha256-W5zNveZuHxQXFggTI+rgB68FDZEFzOcbEXS2oIVhHYY=";

  meta = {
    description = "Terminal UI for live network interface monitoring (Rust)";
    homepage = "https://crates.io/crates/netwatch-tui";
    license = lib.licenses.mit;
    platforms = lib.platforms.unix;
    mainProgram = "netwatch-tui";
  };
}
