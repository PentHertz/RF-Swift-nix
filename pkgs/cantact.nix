# cantact: CLI for the CANtact open-source USB-CAN adapter (Rust crate, the same
# one `cargo install cantact` provides).
{ lib, rustPlatform, fetchCrate, pkg-config, libusb1 }:

rustPlatform.buildRustPackage rec {
  pname = "cantact";
  version = "0.1.2";

  src = fetchCrate {
    inherit pname version;
    hash = "sha256-M8ZAJGWZTEaWP2udHCFPKkp5jQAluMsPD3jTliOVejs=";
  };

  cargoHash = "sha256-Qu3pCOxMGs5RDgaM3jMww2U7ylH35naGLEd9XCEYUEo=";

  nativeBuildInputs = [ pkg-config ];
  buildInputs = [ libusb1 ];

  meta = {
    description = "Command-line tool for the CANtact USB-CAN adapter";
    homepage = "https://github.com/linklayer/cantact-rs";
    license = lib.licenses.mit;
    # The package/crate is named cantact, but its installed CLI is `can`.
    mainProgram = "can";
  };
}
