One library built in two configurations (as dune does for two profiles or
build directories), each with its own generated copy of a platform module,
analyzed together from the source tree. Uses in either configuration keep
a declaration live; sources found only inside a build tree (generated
files) are read from that tree; and units compiled from one source in both
trees resolve to the copy in the consumer's own tree (OCaml >= 5.3), also
when it is in another directory of that tree, as with dune libraries.

  $ mkdir src app
  $ cat > src/lib.ml <<'EOF'
  > type mode = Native_only | Playground_only | Playground_through_reexport | Never_built
  > let hash s = Platform.hash s
  > let native_only () = Native_only
  > let playground_only () = Playground_only
  > let unused () = 0
  > EOF
  $ cat > app/main.ml <<'EOF'
  > let () = ignore (Lib.hash "a"); ignore (Lib.native_only ())
  > EOF
  $ cat > app/playground.ml <<'EOF'
  > let () = ignore (Lib.hash "a"); ignore (Lib.playground_only ())
  > type mode = Lib.mode = Native_only | Playground_only | Playground_through_reexport | Never_built
  > let () = ignore (Playground_through_reexport : mode)
  > EOF

  $ mkdir _build_native _build_native/src _build_native/app
  $ cat > _build_native/src/platform.ml <<'EOF'
  > let hash (s : string) = Hashtbl.hash s
  > let native_unused = 1
  > EOF
  $ cp src/lib.ml _build_native/src/lib.ml
  $ cp app/main.ml _build_native/app/main.ml
  $ (cd _build_native && ocamlc -w -a -bin-annot -I src -c src/platform.ml)
  $ (cd _build_native && ocamlc -w -a -bin-annot -I src -c src/lib.ml)
  $ (cd _build_native && ocamlc -w -a -bin-annot -I src -c app/main.ml)

Different files under one name: their declarations are told apart by
position only, and reports read one of the files (hence the warning).

  $ mkdir _build_browser _build_browser/src _build_browser/app
  $ cat > _build_browser/src/platform.ml <<'EOF'
  > let hash (s : string) = String.length s
  > 
  > let browser_unused = 2
  > EOF
  $ cp src/lib.ml _build_browser/src/lib.ml
  $ cp app/playground.ml _build_browser/app/playground.ml
  $ (cd _build_browser && ocamlc -w -a -bin-annot -I src -c src/platform.ml)
  $ (cd _build_browser && ocamlc -w -a -bin-annot -I src -c src/lib.ml)
  $ (cd _build_browser && ocamlc -w -a -bin-annot -I src -c app/playground.ml)

  $ mkdir scan
  $ ln -s "$PWD/_build_native" scan/native
  $ ln -s "$PWD/_build_browser" scan/browser
  $ reanalyze.exe -ci -debug -dce-cmt "$PWD/scan" > output.out 2> stderr.out

The generated platform.ml differs between the trees: warned about once.

  $ grep -c '^Warning: src/platform.ml differs' stderr.out
  1

  $ grep -m1 -oF -- 'Live Value +lib.+native_only:' output.out
  Live Value +lib.+native_only:
  $ grep -m1 -oF -- 'Dead Value +lib.+native_only:' output.out
  [1]
  $ grep -m1 -oF -- 'Live Value +lib.+playground_only:' output.out
  Live Value +lib.+playground_only:
  $ grep -m1 -oF -- 'Dead Value +lib.+playground_only:' output.out
  [1]
  $ grep -m1 -oF -- 'Live Value +lib.+hash:' output.out
  Live Value +lib.+hash:
  $ grep -m1 -oF -- 'Dead Value +lib.+hash:' output.out
  [1]
  $ grep -m1 -oF -- 'Dead Value +lib.+unused:' output.out
  Dead Value +lib.+unused:

The generated platform copies are scanned from their build trees.

  $ grep -m1 -oF -- 'Live Value +platform.+hash:' output.out
  Live Value +platform.+hash:
  $ grep -m1 -oF -- 'Dead Value +platform.+native_unused:' output.out
  Dead Value +platform.+native_unused:
  $ grep -m1 -oF -- 'Dead Value +platform.+browser_unused:' output.out
  Dead Value +platform.+browser_unused:
  $ grep -m1 -oF -- 'Dead VariantCase +lib.mode.Never_built:' output.out
  Dead VariantCase +lib.mode.Never_built:

A file found from the current directory is still compared with each
tree's copy: here it matches the native copy but not the browser one.

  $ cat > src/platform.ml <<'EOF'
  > let hash (s : string) = Hashtbl.hash s
  > let native_unused = 1
  > EOF
  $ reanalyze.exe -ci -dce-cmt "$PWD/scan" > rerun.out 2> rerun-stderr.out
  $ grep '^Warning: src/platform.ml differs between src/platform.ml and ' rerun-stderr.out \
  >   | grep -F browser/src/platform.ml | grep -cF 'The build is out of date'
  1
