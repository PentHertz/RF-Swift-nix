# dragonforce: offline WPA3/SAE (Dragonblood) password-partitioning brute-forcer
# (FlUxIuS). C++/CMake; builds the `bruter` and `brainpool` tools.
{ lib, stdenv, fetchFromGitHub, cmake, openssl }:

stdenv.mkDerivation {
  pname = "dragonforce";
  version = "unstable";

  src = fetchFromGitHub {
    owner = "FlUxIuS";
    repo = "dragonforce";
    rev = "71a06ecece9657b23c28cec516df5391f5ab33de";
    hash = "sha256-FukcTuOGE2kOY5UIyS0HAQKRC/LEwxFgXrMWMQJS4c4=";
  };

  nativeBuildInputs = [ cmake ];
  buildInputs = [ openssl ];
  env.NIX_CFLAGS_COMPILE = "-Wno-error";

  # Upstream builds in-source (build.sh: `cmake CMakeLists.txt && make`); the
  # multiple project() stanzas don't fit the default out-of-source flow.
  configurePhase = ''
    runHook preConfigure
    cmake -DCMAKE_POLICY_VERSION_MINIMUM=3.5 CMakeLists.txt
    runHook postConfigure
  '';

  installPhase = ''
    runHook preInstall
    mkdir -p $out/bin
    for b in bruter brainpool; do
      [ -f "$b" ] && install -Dm755 "$b" "$out/bin/dragonforce-$b"
    done
    runHook postInstall
  '';

  meta = {
    description = "WPA3/SAE (Dragonblood) offline password-partitioning brute-forcer";
    homepage = "https://github.com/FlUxIuS/dragonforce";
    license = lib.licenses.gpl3Plus;
    platforms = lib.platforms.linux;
  };
}
