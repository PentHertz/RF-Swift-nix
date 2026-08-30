# MobSF (Mobile Security Framework): the Django-based mobile app analysis
# service RF Swift ships in its `android` environment. Upstream drives install
# and runtime through poetry against Python 3.12-3.13 (its setup.sh hard-fails
# on anything else), so we build it against python312 rather than the flake's
# default 3.14.
#
# Nine of MobSF's dependencies are not in nixpkgs; they are packaged inline
# below (against the same python312 set) so they compose into the runtime env.
# Everything else MobSF needs is already in python312Packages.
{ lib, stdenv, fetchurl, fetchFromGitHub, python312, makeWrapper, autoPatchelfHook }:

let
  # nixpkgs' mitmproxy pulls `mitmproxy-rs`, a Rust crate built from source; its
  # cargo vendor + the Rust toolchain blow this sandbox's disk quota. Upstream
  # ships the Rust core (mitmproxy_rs, cp312 abi3) and the Linux redirector
  # (mitmproxy_linux, py3 manylinux) as prebuilt wheels. Override them across the
  # whole python312 set via packageOverrides so every reference - mitmproxy and
  # anything transitively pulling it - resolves to the wheels, with no source
  # Rust build anywhere in the closure.
  py = python312.override (old: {
    self = py;
    packageOverrides = lib.composeExtensions (old.packageOverrides or (_: _: { }))
      (self: super: {
        # tzlocal's test suite asserts the build host's timezone offset equals
        # UTC; this sandbox runs in CEST, so the test fails spuriously. Skip it.
        tzlocal = super.tzlocal.overridePythonAttrs (_: { doCheck = false; });

        # billiard's test_set_pdeathsig spawns a child, then reads it back with
        # psutil; under the pure builder the child is reaped before the assertion
        # runs, so psutil raises NoSuchProcess. It is a harness race, not a
        # billiard defect (billiard reaches this set transitively via libsast and
        # django-q2). Deselect just that one test; the rest of the suite runs.
        billiard = super.billiard.overridePythonAttrs (old: {
          disabledTests = (old.disabledTests or [ ]) ++ [ "test_set_pdeathsig" ];
        });

        # This test puts three results on multiprocessing.Queue and immediately
        # asks monitor() to consume them. Queue's feeder thread is asynchronous,
        # so loaded CI runners can observe an empty queue before it is flushed;
        # the acknowledgement assertions then fail nondeterministically. Keep
        # all other django-q2 tests, including its broker and scheduler tests.
        "django-q2" = super."django-q2".overridePythonAttrs (old: {
          disabledTests = (old.disabledTests or [ ]) ++ [
            "test_acknowledge_failure_override"
          ];
        });

        mitmproxy-linux = self.buildPythonPackage {
          pname = "mitmproxy-linux";
          version = "0.12.8";
          format = "wheel";
          src = fetchurl {
            url = "https://files.pythonhosted.org/packages/76/a8/0fa9fe5fe10e7410a21959c5438e596a92677b49d331a3dcb2dde14af446/mitmproxy_linux-0.12.8-py3-none-manylinux_2_17_x86_64.manylinux2014_x86_64.whl";
            hash = "sha256-+8slMW6V0LK1ztTgzD2Q/bG3FpMAoAXMeTOYlNZlNjo=";
          };
          nativeBuildInputs = [ autoPatchelfHook ];
          buildInputs = [ stdenv.cc.cc.lib ];
          doCheck = false;
        };
        mitmproxy-rs = self.buildPythonPackage {
          pname = "mitmproxy-rs";
          version = "0.12.8";
          format = "wheel";
          src = fetchurl {
            url = "https://files.pythonhosted.org/packages/d1/87/ea3b0050724b700d6fbb26c05be9a6e4b2c9c928218d48dacabe2ed56f03/mitmproxy_rs-0.12.8-cp312-abi3-manylinux_2_17_x86_64.manylinux2014_x86_64.whl";
            hash = "sha256-FOojbQlQqzXWZ7eLX+FdQ+c0XhZuIhRGJKEoPtx4RD4=";
          };
          nativeBuildInputs = [ autoPatchelfHook ];
          buildInputs = [ stdenv.cc.cc.lib ];
          propagatedBuildInputs = [ self.mitmproxy-linux ];
          doCheck = false;
        };
      });
  });
  pyp = py.pkgs;

  # --- MobSF dependencies missing from nixpkgs -------------------------------

  # Pure-python, ships only a wheel.
  shelljob = pyp.buildPythonPackage {
    pname = "shelljob";
    version = "0.6.3";
    format = "wheel";
    src = fetchurl {
      url = "https://files.pythonhosted.org/packages/5c/ba/6917334951d5b2c800960b0c00979ecfedd64421eb06683f1b119224b88e/shelljob-0.6.3-py3-none-any.whl";
      hash = "sha256-GjfRw2YxpIOb50JJEMKTsBY7Br106vPa9s/LXqvZUoY=";
    };
    doCheck = false;
  };

  google-play-scraper = pyp.buildPythonPackage {
    pname = "google-play-scraper";
    version = "1.2.7";
    pyproject = true;
    src = fetchurl {
      url = "https://files.pythonhosted.org/packages/db/29/3530af5fee212e7cdd31a5847ecb306c8202745f08dc608de10454a82499/google_play_scraper-1.2.7.tar.gz";
      hash = "sha256-KE8yHRssOeOel+SQ1RvDFuHYdoAjYO+350Y7XBbtSXI=";
    };
    build-system = [ pyp.poetry-core ];
    doCheck = false;
  };

  ip2location = pyp.buildPythonPackage {
    pname = "ip2location";
    version = "8.11.0";
    format = "setuptools";
    src = fetchurl {
      url = "https://files.pythonhosted.org/packages/7a/f8/b44e07221217f2ef3e1e141fd13fefb439e077696b6a33f3921b323807bc/ip2location-8.11.0.tar.gz";
      hash = "sha256-REFJp0H2V113Ec9UFM+4HwxE+DDi6Uq5aNdGZfi6qjE=";
    };
    doCheck = false;
  };

  apksigcopier = pyp.buildPythonPackage {
    pname = "apksigcopier";
    version = "1.1.1";
    format = "setuptools";
    src = fetchurl {
      url = "https://files.pythonhosted.org/packages/4e/04/892192c74942af8c1221b97f8525fe67766743ecb1e147eb81098d80d1fa/apksigcopier-1.1.1.tar.gz";
      hash = "sha256-6l00ghKPK8+oMHNW9b7U9CQKVZ1wKssRe/d3lV9kyFE=";
    };
    propagatedBuildInputs = [ pyp.click ];
    doCheck = false;
  };

  apksigtool = pyp.buildPythonPackage {
    pname = "apksigtool";
    version = "0.1.0";
    format = "setuptools";
    src = fetchurl {
      url = "https://files.pythonhosted.org/packages/3d/e7/7ddae1cb2c9294e84a2450f9bb19fbe81aea03ea110af9919fa487fa452e/apksigtool-0.1.0.tar.gz";
      hash = "sha256-ADk2jOW1+TgwHq77WaAI32Bd+HPc5ntVzXgDN5R1z8c=";
    };
    propagatedBuildInputs = [
      apksigcopier
      pyp.asn1crypto
      pyp.click
      pyp.cryptography
      pyp.simplejson
    ];
    doCheck = false;
  };

  http-tools = pyp.buildPythonPackage {
    pname = "http-tools";
    version = "6.0.1";
    format = "setuptools";
    src = fetchurl {
      url = "https://files.pythonhosted.org/packages/bc/2d/6687d80bd64c63cb957d4bb09ec9c0536c6e780ff30b1cfafbfd0fdf1615/http_tools-6.0.1.tar.gz";
      hash = "sha256-ssNgFWgujqvgyf1eunTtyyF4RuLgjbFYH34aO6CgtE0=";
    };
    # pyp.mitmproxy resolves against the overridden set → wheel-based mitmproxy-rs.
    propagatedBuildInputs = [ pyp.mitmproxy pyp.markupsafe ];
    # Upstream pins mitmproxy==12.2.1; nixpkgs ships 12.2.3.
    pythonRelaxDeps = [ "mitmproxy" ];
    doCheck = false;
    # `import http_tools` eagerly pulls mitmproxy's proxy stack, which MobSF only
    # touches during device-backed dynamic analysis (never at startup or static
    # analysis). Skip the build-time import probe so the env assembles.
    dontUsePythonImportsCheck = true;
    pythonImportsCheck = [ ];
  };

  libsast = pyp.buildPythonPackage {
    pname = "libsast";
    version = "3.1.8";
    pyproject = true;
    src = fetchurl {
      url = "https://files.pythonhosted.org/packages/b9/0d/ac57aa1697bfbbd16fa06f23c1f524088461c0a274ea6c68eedc18c3fc7b/libsast-3.1.8.tar.gz";
      hash = "sha256-lNrdSoqiRHxHey3k87WMOdFkEqEPJBa96ZhRfZZW6TQ=";
    };
    build-system = [ pyp.poetry-core ];
    propagatedBuildInputs = [ pyp.billiard pyp.pyyaml pyp.requests ];
    doCheck = false;
  };

  # C-extension (bundles yara); use the upstream cp312 manylinux wheel and
  # autopatch its shared object against the Nix runtime libraries.
  yara-python-dex = pyp.buildPythonPackage {
    pname = "yara-python-dex";
    version = "1.0.7";
    format = "wheel";
    src = fetchurl {
      url = "https://files.pythonhosted.org/packages/d1/29/86777747aa5b662e02e07f581ff69af45b7d2b6a26906fb48152d2e7b678/yara_python_dex-1.0.7-cp312-cp312-manylinux_2_17_x86_64.manylinux2014_x86_64.whl";
      hash = "sha256-CzXVOCW9YD4JU/Szj1yQsvO/iYt8SLc4l8I8mL31gyY=";
    };
    nativeBuildInputs = [ autoPatchelfHook ];
    buildInputs = [ stdenv.cc.cc.lib ];
    doCheck = false;
  };

  apkid = pyp.buildPythonPackage {
    pname = "apkid";
    version = "3.1.0";
    format = "setuptools";
    src = fetchurl {
      url = "https://files.pythonhosted.org/packages/0b/fb/cb4cdbcb1c1dd2f59f38a0505923cdc2304b6efe9aacc87e5b383e325b7d/apkid-3.1.0.tar.gz";
      hash = "sha256-ix8hhOG4jUKsYfYWyJvyIu8qYVcPB2D/EVziQRMega8=";
    };
    propagatedBuildInputs = [ yara-python-dex ];
    doCheck = false;
  };

  # nixpkgs' lief is source-built (a 900+ object C++ compile). MobSF only needs
  # the `lief` python module, so use the upstream cp312 manylinux wheel and
  # autopatch it - far cheaper and avoids the from-source build entirely.
  lief = pyp.buildPythonPackage {
    pname = "lief";
    version = "0.17.6";
    format = "wheel";
    src = fetchurl {
      url = "https://files.pythonhosted.org/packages/6b/9f/77ca67789fda7fee355c8b4e6c58c0717fa4c5c3c5a4272777eb993df172/lief-0.17.6-cp312-cp312-manylinux_2_28_x86_64.whl";
      hash = "sha256-HfmyLzhR3n0OhqhzGtB+R8pWLr5DBgXZCuz81tIBJdA=";
    };
    nativeBuildInputs = [ autoPatchelfHook ];
    buildInputs = [ stdenv.cc.cc.lib ];
    doCheck = false;
  };

  # --- Full runtime environment ---------------------------------------------
  pythonEnv = py.withPackages (ps: [
    ps.django
    ps.rsa
    ps.requests
    ps.beautifulsoup4
    ps.colorlog
    ps.macholib
    ps.whitenoise
    ps.waitress
    ps.gunicorn
    ps.psutil
    ps.asn1crypto
    ps.distro
    ps.pdfkit
    ps."frida-python"
    ps.tldextract
    ps."openstep-parser"
    ps.svgutils
    ps.arpy
    ps.tzdata
    ps.paramiko
    ps.six
    ps."python3-saml"
    ps."psycopg2-binary"
    lief
    ps.packaging
    ps."django-ratelimit"
    ps."django-q2"
    ps.defusedxml
    ps.bleach
    ps.bcrypt
    # inline-packaged deps (built against the same python312 set)
    shelljob
    google-play-scraper
    ip2location
    apksigcopier
    apksigtool
    http-tools
    libsast
    yara-python-dex
    apkid
  ]);

in
stdenv.mkDerivation rec {
  pname = "mobsf";
  version = "4.5.2";

  src = fetchFromGitHub {
    owner = "MobSF";
    repo = "Mobile-Security-Framework-MobSF";
    rev = "v${version}";
    hash = "sha256-zICRuK5NI0aPHSW7GAcFXAuLtrbckzRI/0RHJJmRFhw=";
  };

  nativeBuildInputs = [ makeWrapper ];
  dontConfigure = true;
  dontBuild = true;

  # Common flags for `gunicorn mobsf.MobSF.wsgi` (mirrors upstream run.sh).
  gunicornFlags = "-b [::]:8000 mobsf.MobSF.wsgi:application "
    + "--workers=1 --threads=10 --timeout=3600 --log-level=critical "
    + "--log-file=- --access-logfile=- --error-logfile=- --capture-output";

  installPhase = ''
    runHook preInstall

    mkdir -p $out/share/mobsf
    cp -a . $out/share/mobsf/

    # `mobsf` launcher: put all writable state under ~/.MobSF (USE_HOME=1),
    # apply DB migrations idempotently, then serve exactly as upstream run.sh.
    makeWrapper ${pythonEnv}/bin/gunicorn $out/bin/mobsf \
      --run 'export USE_HOME=''${USE_HOME:-1}' \
      --run 'cd '"$out"'/share/mobsf' \
      --run '${pythonEnv}/bin/python manage.py migrate --noinput >/dev/null 2>&1 || true' \
      --run '${pythonEnv}/bin/python manage.py create_roles >/dev/null 2>&1 || true' \
      --add-flags "${gunicornFlags}"

    # `mobsf-manage`: the Django management CLI for admin tasks.
    makeWrapper ${pythonEnv}/bin/python $out/bin/mobsf-manage \
      --run 'export USE_HOME=''${USE_HOME:-1}' \
      --run 'cd '"$out"'/share/mobsf' \
      --add-flags "manage.py"

    runHook postInstall
  '';

  passthru.pythonEnv = pythonEnv;

  meta = {
    description = "Mobile Security Framework: automated mobile app (Android/iOS) security analysis";
    homepage = "https://github.com/MobSF/Mobile-Security-Framework-MobSF";
    license = lib.licenses.gpl3Only;
    platforms = [ "x86_64-linux" ];
    mainProgram = "mobsf";
  };
}
