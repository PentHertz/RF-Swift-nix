# BeEF - the Browser Exploitation Framework (beefproject/beef). It is a Ruby
# application run from its own source tree (not a gem and not a CLI in the usual
# sense: `beef` starts the framework and its web UI / hook server), which is why
# RF Swift's images run it as a service. We build its gem closure from the
# upstream Gemfile.lock with bundlerEnv (gemset.nix is bundix-generated and
# pinned here, next to a copy of the Gemfile/Gemfile.lock), then wrap BeEF's own
# `beef` launcher with that Ruby.
#
# Runtime helpers BeEF shells out to: a JavaScript engine for the `execjs` gem
# (uglifier minifies BeEF's hook JS through it) and the `espeak` binary for the
# `espeak-ruby` text-to-voice gem. Both are put on the wrapper PATH.
{ lib, stdenv, fetchFromGitHub, bundlerEnv, ruby_3_4, makeWrapper
, nodejs, espeak-ng }:

let
  gems = bundlerEnv {
    name = "beef-gems";
    ruby = ruby_3_4;
    # Gemfile, Gemfile.lock and gemset.nix live in this directory.
    gemdir = ./.;
  };
in
stdenv.mkDerivation {
  pname = "beef";
  version = "0.5.4.0-unstable-2026-08-30";

  src = fetchFromGitHub {
    owner = "beefproject";
    repo = "beef";
    rev = "6de1c54c018e1a04d84bd255751923841a610d55";
    hash = "sha256-TuvJFJEvc1SPeDQVOOCd+8yrgRIsnd1iMsEKO2JIAiE=";
  };

  nativeBuildInputs = [ makeWrapper ];
  dontBuild = true;

  installPhase = ''
    runHook preInstall

    mkdir -p $out/share/beef $out/bin
    cp -a . $out/share/beef

    # BeEF resolves its own root from realpath(__FILE__), so it must run its own
    # launcher script; the bundlerEnv Ruby supplies the gem closure. chdir keeps
    # relative config/extension paths working when started from anywhere.
    makeWrapper ${gems}/bin/ruby $out/bin/beef \
      --add-flags "$out/share/beef/beef" \
      --chdir "$out/share/beef" \
      --prefix PATH : ${lib.makeBinPath [ nodejs espeak-ng ]}

    runHook postInstall
  '';

  meta = {
    description = "BeEF, the Browser Exploitation Framework (run as a service)";
    homepage = "https://beefproject.com/";
    license = lib.licenses.free; # BeEF's own dual license (see doc/COPYING).
    mainProgram = "beef";
    platforms = lib.platforms.unix;
  };
}
