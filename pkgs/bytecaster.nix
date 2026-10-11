# ByteCaster: encrypts/encodes/obfuscates a payload and dumps it as a byte array
# in one of 14 output formats. Matches RF-Swift-images' bytecaster_install, which
# clones the FlUxIuS fork of Print3M/ByteCaster and runs
# `CGO_ENABLED=0 go build -ldflags="-w -s" -tags netgo -o ByteCaster`.
# Pure standard library (no go.sum), hence vendorHash = null.
{ lib, buildGoModule, fetchFromGitHub }:

buildGoModule {
  pname = "bytecaster";
  version = "unstable-2025-09-20";

  src = fetchFromGitHub {
    owner = "FlUxIuS";
    repo = "ByteCaster";
    rev = "91de91623577a037bdb5f51001098f38d5a7b586";
    hash = "sha256-smUUojcv4hBgKdOK3As28zWjASJonzD4TIvEnKXGwlg=";
  };

  vendorHash = null;

  env.CGO_ENABLED = 0;
  tags = [ "netgo" ];
  ldflags = [ "-w" "-s" ];

  # Keep the image's command name (the module is called "bytecaster").
  postInstall = ''
    mv $out/bin/bytecaster $out/bin/ByteCaster
  '';

  meta = {
    description = "Payload encryption, obfuscation and conversion to byte arrays (14 output formats)";
    homepage = "https://github.com/FlUxIuS/ByteCaster";
    # Upstream (Print3M/ByteCaster) publishes no license.
    license = lib.licenses.unfree;
    platforms = lib.platforms.unix;
    mainProgram = "ByteCaster";
  };
}
