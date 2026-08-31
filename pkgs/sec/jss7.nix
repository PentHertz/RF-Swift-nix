# jSS7 (PentHertz/jss7): the RestComm/Mobicents SS7 protocol stack - MTP, M3UA,
# SCCP, TCAP (ITU + ANSI), MAP, CAP, INAP and the shell tooling - as a Maven
# multi-module Java library. It has no CLI of its own; it is the SS7 stack that
# SigPloit and similar tools load, which is why RF Swift's images just
# `mvn install` it (telecom_software.sh: jss7_soft_install, x86_64 only).
#
# Built from source with maven.buildMavenPackage: Maven resolves the whole
# dependency closure into a fixed-output derivation (mvnHash) once, then the
# modules build offline. The tree targets Java 8+ (`<jdk>[1.8,)`), so it is
# built with JDK 11 - the oldest LTS in this pin and the safest for the legacy
# RestComm code.
#
# NOTE: mvnHash below is pinned from a real `nix build .#pkg-jss7` (the Maven
# closure is fetched once into a fixed-output derivation and hashed). If the tree
# or the maven pin changes, regenerate it the same way: set mvnHash to
# lib.fakeHash, build, and paste the hash Nix prints.
{ lib, maven, jdk11, fetchFromGitHub }:

maven.buildMavenPackage {
  pname = "jss7";
  version = "8.0.0-unstable-2026-08-30";

  src = fetchFromGitHub {
    owner = "PentHertz";
    repo = "jss7";
    rev = "1659317d949bf6671d97dc484fffcd4050dcb69b";
    hash = "sha256-VjaiF0XaVblwrC6Rrc21pLBd3nmbsvjlZcYRUft1NVw=";
  };

  mvnJdk = jdk11;
  doCheck = false; # -DskipTests, matching the images.

  mvnHash = "sha256-D2RG8bHSSRFBJmUW2Ax39B8OU7GcO2sT7obavXmkcxs=";

  # jss7 is a library set, not an app: collect every module's built jar into a
  # shared java directory so downstream tooling can put them on the classpath.
  installPhase = ''
    runHook preInstall
    mkdir -p $out/share/java
    find . -path '*/target/*.jar' \
      ! -name '*-sources.jar' ! -name '*-tests.jar' ! -name 'original-*.jar' \
      -exec cp -v {} $out/share/java/ \;
    runHook postInstall
  '';

  meta = {
    description = "jSS7: RestComm/Mobicents SS7 protocol stack (MTP/M3UA/SCCP/TCAP/MAP/CAP/INAP), Java library";
    homepage = "https://github.com/PentHertz/jss7";
    license = lib.licenses.agpl3Only; # RestComm jSS7 is AGPL-3.0.
    platforms = [ "x86_64-linux" ];
    sourceProvenance = [ lib.sourceTypes.fromSource ];
  };
}
