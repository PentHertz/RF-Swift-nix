# mkVendorBinary: wrap a proprietary prebuilt binary (or SDK) as a Nix package.
#
# Nix can absolutely ship closed-source binaries. The trick is:
#   1. don't build anything (dontBuild), just unpack the vendor artifact;
#   2. let autoPatchelfHook rewrite each ELF's interpreter + RPATH to point at
#      Nix store copies of its shared-library dependencies;
#   3. install the binaries/libs into $out and, if needed, wrap them so runtime
#      library and firmware paths are set.
#
# Sourcing the artifact:
#   * `src = fetchurl { url = "https://vendor/.../tool.tar.gz"; hash = ...; }`
#     when the vendor exposes a stable public URL.
#   * `src = requireFile { name = "tool.tar.gz"; hash = ...;
#       message = "Download from <vendor portal> and run: nix-store --add-fixed sha256 tool.tar.gz"; }`
#     when it sits behind a EULA / login. The user fetches it once; Nix caches it
#     in the store by hash from then on.
#
# This is a thin, opinionated wrapper over stdenv.mkDerivation so the several RF
# Swift vendor SDKs (SignalHound, Harogic, KCSDI, KC908, ...) stay DRY.
{ lib, stdenv, autoPatchelfHook, makeWrapper, dpkg, unzip, gnutar }:

{
  pname,
  version,
  src,
  # Runtime shared libraries the blob links against (buildInputs).
  libraries ? [ ],
  # If the artifact is a .deb, set true so it is extracted with dpkg.
  isDeb ? false,
  # Relative paths inside the unpacked tree to install as executables.
  # Each is symlinked into $out/bin. Empty = install the whole tree under
  # $out/opt and let the caller add bin symlinks in extraInstall.
  binaries ? [ ],
  # Extra shell run at the end of installPhase (udev rules, wrappers, etc.).
  extraInstall ? "",
  # LD_LIBRARY_PATH additions for wrapped binaries (rarely needed once
  # autoPatchelf has run, but some SDKs dlopen() plugins at runtime).
  runtimeLibs ? [ ],
  meta ? { },
}:

stdenv.mkDerivation (finalAttrs: {
  inherit pname version src;

  nativeBuildInputs = [ autoPatchelfHook makeWrapper unzip gnutar ] ++ lib.optional isDeb dpkg;
  buildInputs = libraries;

  # Vendor blobs pull in libs we don't ship; list them here rather than fail
  # the build if a truly-optional plugin dep is absent.
  # autoPatchelfIgnoreMissingDeps = [ "libFoo.so" ];

  dontBuild = true;
  dontConfigure = true;

  unpackPhase = lib.optionalString isDeb ''
    runHook preUnpack
    dpkg-deb -x $src ./unpacked
    runHook postUnpack
  '' + lib.optionalString (!isDeb) ''
    runHook preUnpack
    mkdir -p unpacked
    if [ -d "$src" ]; then cp -r "$src"/. unpacked/;
    else tar -xf "$src" -C unpacked --strip-components=0 || (cd unpacked && unzip -q "$src"); fi
    runHook postUnpack
  '';

  installPhase = ''
    runHook preInstall
    mkdir -p $out/opt/${finalAttrs.pname} $out/bin
    cp -r unpacked/. $out/opt/${finalAttrs.pname}/
  '' + lib.concatMapStrings (b: ''
    install -Dm755 "$out/opt/${finalAttrs.pname}/${b}" "$out/bin/$(basename ${b})"
  '') binaries + ''
    ${extraInstall}
    runHook postInstall
  '';

  postFixup = lib.optionalString (runtimeLibs != [ ]) ''
    for f in $out/bin/*; do
      wrapProgram "$f" --prefix LD_LIBRARY_PATH : "${lib.makeLibraryPath runtimeLibs}"
    done
  '';

  meta = {
    sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
    license = lib.licenses.unfree;
    platforms = lib.platforms.linux;
  } // meta;
})
