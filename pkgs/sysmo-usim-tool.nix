# sysmo-usim-tool: configure sysmocom SIM/USIM/ISIM cards (SJS1 / SJA2 / SJA5).
{ lib, stdenv, fetchFromGitHub, makeWrapper, python3, pcsclite }:

let
  pyEnv = python3.withPackages (ps: with ps; [ pyscard pyserial ]);
in
stdenv.mkDerivation {
  pname = "sysmo-usim-tool";
  version = "unstable";

  src = fetchFromGitHub {
    owner = "sysmocom";
    repo = "sysmo-usim-tool";
    rev = "190c95b959c62b270efdd6c48e330cc237f179dd";
    hash = "sha256-s3b4lJjqr5TYo0hIDApFxwQtgiRpoypdBYq8PBe9Z9A=";
  };

  nativeBuildInputs = [ makeWrapper ];
  dontBuild = true;

  installPhase = ''
    runHook preInstall
    mkdir -p $out/share/sysmo-usim-tool $out/bin
    cp -r . $out/share/sysmo-usim-tool/
    for f in sysmo-usim-tool.sjs1 sysmo-isim-tool.sja2 sysmo-isim-tool.sja5; do
      if [ -f "$out/share/sysmo-usim-tool/$f.py" ]; then
        makeWrapper ${pyEnv}/bin/python3 "$out/bin/$f" \
          --add-flags "$out/share/sysmo-usim-tool/$f.py" \
          --chdir "$out/share/sysmo-usim-tool" \
          --prefix PYTHONPATH : "$out/share/sysmo-usim-tool"
      fi
    done
    runHook postInstall
  '';

  meta = {
    description = "Tool to configure sysmocom programmable SIM/USIM/ISIM cards";
    homepage = "https://github.com/sysmocom/sysmo-usim-tool";
    license = lib.licenses.gpl2Plus;
    platforms = lib.platforms.linux;
  };
}
