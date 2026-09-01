# drozer: Android security assessment framework (WithSecure). The console is a
# normal Python app; setup.py compiles the small agent helper APKs with javac
# using the android.jar and d8 dexer BUNDLED in the repo (no Android SDK needed),
# so a JDK is the only extra build tool.
{ lib, python3Packages, fetchFromGitHub, jdk }:
let pick = names: lib.filter (x: x != null) (map (n: python3Packages.${n} or null) names);
in python3Packages.buildPythonApplication {
  pname = "drozer"; version = "unstable"; pyproject = true;
  src = fetchFromGitHub { owner = "WithSecureLabs"; repo = "drozer"; rev = "d992f6378d42680ea96ee03eff4117f150e1049c"; hash = "sha256-a/CCLg2g//H3aVX6rDVXQ1w7+YCI0/hg1mitTTff4Z0="; };
  nativeBuildInputs = [ jdk ];
  # setup.py compiles the agent helper APKs at build time by invoking the bundled
  # `d8` dexer wrapper, which ships a `#!/bin/bash` shebang. The pure Nix builder
  # has no /bin/bash, so d8 silently fails to run, no `.zip` is produced, and the
  # subsequent `.zip`->`.apk` rename dies with FileNotFoundError. Point the wrapper
  # at a real bash. (d8 itself finds `java` via the jdk on the build PATH.)
  postPatch = ''
    patchShebangs src/drozer/lib/d8
  '';
  build-system = pick [ "setuptools" ];
  dependencies = pick [ "protobuf" "pyopenssl" "twisted" "service-identity" "distro" "click" "pyyaml" ];
  pythonRelaxDeps = true; dontCheckRuntimeDeps = true; doCheck = false;
  meta = { description = "Android security assessment framework"; homepage = "https://github.com/WithSecureLabs/drozer"; license = lib.licenses.bsd3; mainProgram = "drozer"; };
}
