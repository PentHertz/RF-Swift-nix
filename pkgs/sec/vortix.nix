# vortix: published Rust CLI (crates.io), pinned to the version RF Swift's image
# installs. buildRustPackage builds it from the crate's own Cargo.lock.
{ lib, rustPlatform, fetchCrate }:

rustPlatform.buildRustPackage rec {
  pname = "vortix";
  version = "0.4.1";

  src = fetchCrate {
    inherit pname version;
    hash = "sha256-zSyaMRdIoadQ4KcuGHBQjDVPNYz/Mn8gtc7ZZIY7b64=";
  };

  cargoHash = "sha256-DmfiCNpFTdlrdf8thGtQmAKMU8QeYhgm792Vq0YMCqQ=";

  meta = {
    description = "vortix network utility (Rust)";
    homepage = "https://crates.io/crates/vortix";
    license = lib.licenses.mit;
    platforms = lib.platforms.unix;
    mainProgram = "vortix";
  };
}
