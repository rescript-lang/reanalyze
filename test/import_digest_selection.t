The importer was compiled against digest_a. A mismatching Collision unit
beside it must not hide that dependency or replace it when it is absent.

  $ ROOT=$PWD
  $ cp -r ../examples/regression . && cd regression
  $ dune build --root . 2>&1
  $ mkdir -p "$ROOT/temp/layout/provider" "$ROOT/temp/layout/consumer"
  $ cp _build/default/digest_a/.digest_a.objs/byte/collision.cmt "$ROOT/temp/layout/provider"
  $ cp _build/default/digest_b/.digest_b.objs/byte/collision.cmt "$ROOT/temp/layout/consumer"
  $ cp _build/default/digest_use/.digest_use.objs/byte/use_collision.cmt "$ROOT/temp/layout/consumer"

Import digest before sibling preference.

  $ reanalyze.exe -ci -debug -native-build-target . -dce-cmt "$ROOT/temp/layout" > present.out 2>/dev/null
  $ grep -m1 -oF -- 'Live Value +Collision.Chosen_impl.+g' present.out
  Live Value +Collision.Chosen_impl.+g
  $ grep -m1 -oF -- 'Dead Value +Collision.Unrelated_impl.+g' present.out
  Dead Value +Collision.Unrelated_impl.+g
  $ grep -m1 -oF -- 'optional argument x of function Chosen_impl.+g is always supplied (1 calls)' present.out
  optional argument x of function Chosen_impl.+g is always supplied (1 calls)
  $ grep -m1 -oF -- 'Live Value +Collision.Unrelated_impl.+g' present.out
  [1]

A missing imported digest stays unresolved.

  $ mv "$ROOT/temp/layout/provider/collision.cmt" "$ROOT/temp/collision.cmt"
  $ reanalyze.exe -ci -debug -native-build-target . -dce-cmt "$ROOT/temp/layout" > absent.out 2>/dev/null
  $ grep -m1 -oF -- 'Dead Value +Collision.Unrelated_impl.+g' absent.out
  Dead Value +Collision.Unrelated_impl.+g
  $ grep -m1 -oF -- 'Live Value +Collision.Unrelated_impl.+g' absent.out
  [1]
  $ grep -m1 -oF -- 'function Unrelated_impl.+g is always supplied' absent.out
  [1]
