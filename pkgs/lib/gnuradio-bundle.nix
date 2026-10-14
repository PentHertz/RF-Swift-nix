# Shell snippets appended to the buildCommand of RF Swift's GNU Radio wrappers
# (gnuradio-rfswift, gnuradio-rfswift-light).
{ lib }:

{
  # Links the example flowgraphs of the bundled OOT modules (each package's
  # share/gnuradio/examples) next to GNU Radio's own in the wrapper's output.
  # That one tree is what GRC's example browser reads (it takes a single
  # examples_path) and what an environment's profile shows. lndir builds real
  # directories holding links to the files: the browser walks the tree with
  # os.walk, which does not descend into linked directories.
  linkExamples = packages: ''
    mkdir -p "$out/share/gnuradio/examples"
    for p in ${lib.concatMapStringsSep " " toString packages}; do
      if [ -d "$p/share/gnuradio/examples" ]; then
        lndir -silent "$p/share/gnuradio/examples" "$out/share/gnuradio/examples"
      fi
    done
  '';

  # The wrapper's own copy of the gnuradio-companion launcher gets the Qt
  # interface's locale fix (see grc-locale-fix.py); GNU Radio itself, which every
  # OOT module builds against, stays untouched. Fails the build if the launcher
  # changes shape.
  fixQtLocale = ''
    grc=$out/bin/.gnuradio-companion-wrapped
    sed -i "/^import sys$/r ${./grc-locale-fix.py}" "$grc"
    grep -q _rfswift_getdefaultlocale "$grc"
  '';
}
