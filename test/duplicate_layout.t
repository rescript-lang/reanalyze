A broad root may hold copies of the same compiled unit (a library's
objects and its _build/install copy, byte and native objects). Scanning
such a root must give exactly the single-directory result: copies are
neither scanned twice nor mistaken for distinct units.

  $ ROOT=$PWD
  $ cp -r ../examples/regression . && cd regression
  $ dune build --root . 2>&1
  $ CMT=$PWD/_build/default/src/.regression_fixture.objs/byte

Dependencies duplicated in a and b, consumers in c.

  $ mkdir "$ROOT/dup" "$ROOT/dup/a" "$ROOT/dup/b" "$ROOT/dup/c"
  $ for file in "$CMT"/*.cmt "$CMT"/*.cmti; do
  >   case $(basename "$file") in
  >     *Shared_signature*|*Cross_*) cp "$file" "$ROOT/dup/a"; cp "$file" "$ROOT/dup/b";;
  >     *) cp "$file" "$ROOT/dup/c";;
  >   esac
  > done

  $ reanalyze.exe -ci -native-build-target . -dce-cmt "$CMT" > single.out 2>/dev/null
  $ reanalyze.exe -ci -native-build-target . -dce-cmt "$ROOT/dup" > duplicated.out 2>/dev/null
  $ grep -E 'never used|always supplied|dead module' single.out | LC_ALL=C sort > single.sorted
  $ grep -E 'never used|always supplied|dead module' duplicated.out | LC_ALL=C sort > duplicated.sorted
  $ cmp single.sorted duplicated.sorted
