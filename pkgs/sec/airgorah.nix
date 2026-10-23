# Airgorah 0.9.0 (nixpkgs has 0.8.1), as the wifi images install it. Since 0.9
# the GTK GUI drives a separate privileged `airgorah-agent`, which must sit in
# the same directory as the GUI binary: both workspace crates are built and
# installed into bin/ side by side. Run as root (as in RF Swift) the GUI starts
# the agent directly, without pkexec (X11 only, not Wayland).
{ lib, airgorah, fetchFromGitHub, iproute2, crunch, xterm }:

airgorah.overrideAttrs (finalAttrs: old: {
  version = "0.9.0";

  src = fetchFromGitHub {
    owner = "martin-olivier";
    repo = "airgorah";
    tag = "v${finalAttrs.version}";
    hash = "sha256-qsDSdylyRNGWvru59eB9u7ZLCA3m++vtYGpDOcWUz/s=";
  };

  cargoHash = "sha256-T+VbYhpl81jgGjyoOKO2U/nq/s+hJ6DnGQeFGZpV5wo=";

  # The images' runtime set: nixpkgs already puts iw, aircrack-ng, tshark and
  # macchanger on PATH; add ip, crunch and xterm.
  preFixup = (old.preFixup or "") + ''
    gappsWrapperArgs+=(--prefix PATH : ${lib.makeBinPath [ iproute2 crunch xterm ]})
  '';

  meta = old.meta // {
    changelog = "https://github.com/martin-olivier/airgorah/releases/tag/v${finalAttrs.version}";
  };
})
