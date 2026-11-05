Nested_arguments_packed and its consumer Nested_arguments in both scan orders:
call attribution must not depend on the order in which units are scanned.

  $ ROOT=$PWD
  $ cp -r ../examples/regression . && cd regression
  $ dune build --root . 2>&1
  $ CMT=_build/default/src/.regression_fixture.objs/byte
  $ mkdir "$ROOT/scan" "$ROOT/scan/first" "$ROOT/scan/second"

Nested_arguments_packed in first, all other units in second.

  $ cp "$CMT"/*.cmt "$CMT"/*.cmti "$ROOT/scan/second"
  $ mv "$ROOT/scan/second/regression_fixture__Nested_arguments_packed.cmt" "$ROOT/scan/first"
  $ reanalyze.exe -ci -debug -native-build-target . -dce-cmt "$ROOT/scan" > first.out 2>/dev/null
  $ grep -m1 -oF -- 'Scanning regression_fixture__Nested_arguments_packed.cmt ' first.out
  Scanning regression_fixture__Nested_arguments_packed.cmt 
  $ grep -m1 -oF -- 'Scanning regression_fixture__Nested_arguments.cmt ' first.out
  Scanning regression_fixture__Nested_arguments.cmt 
  $ grep -m1 -oE 'Scanning regression_fixture__(Nested_arguments_packed|Nested_arguments)\.cmt ' first.out > first.order
  $ grep -m1 -oF -- 'optional argument foreign_nested of function Actual.N.+g is always supplied (1 calls)' first.out
  optional argument foreign_nested of function Actual.N.+g is always supplied (1 calls)
  $ grep -m1 -oF -- 'optional argument foreign_nested of function Unrelated.N.+g is never used' first.out
  optional argument foreign_nested of function Unrelated.N.+g is never used
  $ rm "$ROOT"/scan/first/* "$ROOT"/scan/second/*

Nested_arguments_packed in second, all other units in first.

  $ cp "$CMT"/*.cmt "$CMT"/*.cmti "$ROOT/scan/first"
  $ mv "$ROOT/scan/first/regression_fixture__Nested_arguments_packed.cmt" "$ROOT/scan/second"
  $ reanalyze.exe -ci -debug -native-build-target . -dce-cmt "$ROOT/scan" > second.out 2>/dev/null
  $ grep -m1 -oF -- 'Scanning regression_fixture__Nested_arguments_packed.cmt ' second.out
  Scanning regression_fixture__Nested_arguments_packed.cmt 
  $ grep -m1 -oF -- 'Scanning regression_fixture__Nested_arguments.cmt ' second.out
  Scanning regression_fixture__Nested_arguments.cmt 
  $ grep -m1 -oE 'Scanning regression_fixture__(Nested_arguments_packed|Nested_arguments)\.cmt ' second.out > second.order
  $ grep -m1 -oF -- 'optional argument foreign_nested of function Actual.N.+g is always supplied (1 calls)' second.out
  optional argument foreign_nested of function Actual.N.+g is always supplied (1 calls)
  $ grep -m1 -oF -- 'optional argument foreign_nested of function Unrelated.N.+g is never used' second.out
  optional argument foreign_nested of function Unrelated.N.+g is never used
  $ rm "$ROOT"/scan/first/* "$ROOT"/scan/second/*

The two runs scanned the units in opposite orders.

  $ cmp -s first.order second.order
  [1]
