Unpacked_unused and its consumer Unpacked_open in both scan orders:
call attribution must not depend on the order in which units are scanned.

  $ ROOT=$PWD
  $ cp -r ../examples/regression . && cd regression
  $ dune build --root . 2>&1
  $ CMT=_build/default/src/.regression_fixture.objs/byte
  $ mkdir "$ROOT/scan" "$ROOT/scan/first" "$ROOT/scan/second"

Unpacked_unused in first, all other units in second.

  $ cp "$CMT"/*.cmt "$CMT"/*.cmti "$ROOT/scan/second"
  $ mv "$ROOT/scan/second/regression_fixture__Unpacked_unused.cmt" "$ROOT/scan/first"
  $ reanalyze.exe -ci -debug -native-build-target . -dce-cmt "$ROOT/scan" > first.out 2>/dev/null
  $ grep -m1 -oF -- 'Scanning regression_fixture__Unpacked_unused.cmt ' first.out
  Scanning regression_fixture__Unpacked_unused.cmt 
  $ grep -m1 -oF -- 'Scanning regression_fixture__Unpacked_open.cmt ' first.out
  Scanning regression_fixture__Unpacked_open.cmt 
  $ grep -m1 -oE 'Scanning regression_fixture__(Unpacked_unused|Unpacked_open)\.cmt ' first.out > first.order
  $ grep -m1 -oF -- 'optional argument unused_open of function Unused_import.Victim.+g is never used' first.out
  optional argument unused_open of function Unused_import.Victim.+g is never used
  $ grep -m1 -oF -- 'optional argument unused_open of function Unused_import.Called_victim.+g is never used' first.out
  optional argument unused_open of function Unused_import.Called_victim.+g is never used
  $ grep -m1 -oF -- 'optional argument unused_open of function Mixed_open.Victim.+g is never used' first.out
  optional argument unused_open of function Mixed_open.Victim.+g is never used
  $ grep -m1 -oF -- 'optional argument foreign_alias of function Aliases.Foreign_alias_arg.+g is always supplied (1 calls)' first.out
  optional argument foreign_alias of function Aliases.Foreign_alias_arg.+g is always supplied (1 calls)
  $ grep -m1 -oF -- 'optional argument foreign_include of function Aliases.Foreign_include_arg.+g is always supplied (1 calls)' first.out
  optional argument foreign_include of function Aliases.Foreign_include_arg.+g is always supplied (1 calls)
  $ rm "$ROOT"/scan/first/* "$ROOT"/scan/second/*

Unpacked_unused in second, all other units in first.

  $ cp "$CMT"/*.cmt "$CMT"/*.cmti "$ROOT/scan/first"
  $ mv "$ROOT/scan/first/regression_fixture__Unpacked_unused.cmt" "$ROOT/scan/second"
  $ reanalyze.exe -ci -debug -native-build-target . -dce-cmt "$ROOT/scan" > second.out 2>/dev/null
  $ grep -m1 -oF -- 'Scanning regression_fixture__Unpacked_unused.cmt ' second.out
  Scanning regression_fixture__Unpacked_unused.cmt 
  $ grep -m1 -oF -- 'Scanning regression_fixture__Unpacked_open.cmt ' second.out
  Scanning regression_fixture__Unpacked_open.cmt 
  $ grep -m1 -oE 'Scanning regression_fixture__(Unpacked_unused|Unpacked_open)\.cmt ' second.out > second.order
  $ grep -m1 -oF -- 'optional argument unused_open of function Unused_import.Victim.+g is never used' second.out
  optional argument unused_open of function Unused_import.Victim.+g is never used
  $ grep -m1 -oF -- 'optional argument unused_open of function Unused_import.Called_victim.+g is never used' second.out
  optional argument unused_open of function Unused_import.Called_victim.+g is never used
  $ grep -m1 -oF -- 'optional argument unused_open of function Mixed_open.Victim.+g is never used' second.out
  optional argument unused_open of function Mixed_open.Victim.+g is never used
  $ grep -m1 -oF -- 'optional argument foreign_alias of function Aliases.Foreign_alias_arg.+g is always supplied (1 calls)' second.out
  optional argument foreign_alias of function Aliases.Foreign_alias_arg.+g is always supplied (1 calls)
  $ grep -m1 -oF -- 'optional argument foreign_include of function Aliases.Foreign_include_arg.+g is always supplied (1 calls)' second.out
  optional argument foreign_include of function Aliases.Foreign_include_arg.+g is always supplied (1 calls)
  $ rm "$ROOT"/scan/first/* "$ROOT"/scan/second/*

The two runs scanned the units in opposite orders.

  $ cmp -s first.order second.order
  [1]
