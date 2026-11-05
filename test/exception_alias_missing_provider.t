A wrapped exception include analyzed without its provider unit.

  $ ROOT=$PWD
  $ cp -r ../examples/regression . && cd regression
  $ dune build --root . 2>&1

Scan the regression fixture without regression_fixture__Exception_alias_exports.

  $ mkdir "$ROOT/scan"
  $ cp _build/default/src/.regression_fixture.objs/byte/*.cmt _build/default/src/.regression_fixture.objs/byte/*.cmti "$ROOT/scan"
  $ rm "$ROOT/scan/regression_fixture__Exception_alias_exports.cmt"
  $ reanalyze.exe -ci -debug -native-build-target . -dce-cmt "$ROOT/scan" > output.out 2>/dev/null

The generated wrapper source may be absent, but its aliases must be read.

  $ test -f "$ROOT/scan/regression_fixture.cmt"
  $ grep -m1 -oF -- 'Scanning regression_fixture__Exception_alias_include.cmt ' output.out
  Scanning regression_fixture__Exception_alias_include.cmt 
  $ grep -m1 -oF -- 'Scanning regression_fixture__Exception_alias_exports.cmt ' output.out
  [1]
  $ grep -m1 -oF -- 'Live Exception +Exception_nested_source.Inner.Through_include' output.out
  Live Exception +Exception_nested_source.Inner.Through_include
  $ grep -m1 -oF -- 'Dead Exception +Exception_nested_source.Inner.Through_include' output.out
  [1]
  $ grep -m1 -oF -- 'Dead Exception +Exception_nested_source.Inner.Unused' output.out
  Dead Exception +Exception_nested_source.Inner.Unused
