Functor identity with shared dependency interfaces: Shared and
Relay are compiled once against a/Provider and once against b/Provider.

  $ FIXTURE=../examples/regression/compilation_context
  $ mkdir -p a b native_layout/byte native_layout/native
  $ cp "$FIXTURE/Shared.ml" Shared.ml
  $ cp "$FIXTURE/Relay.ml" Relay.ml
  $ mkdir api
  $ cp "$FIXTURE/Provider.mli" Provider.mli
  $ ocamlc -bin-annot -bin-annot-occurrences -c -o api/Provider.cmi Provider.mli
  $ cp "$FIXTURE/a/Provider.ml" a/Provider.ml
  $ cp "$FIXTURE/a/Use_a.ml" a/Use_a.ml
  $ ocamlc -bin-annot -bin-annot-occurrences -intf-suffix .ml -I api -c a/Provider.ml
  $ ocamlc -bin-annot -bin-annot-occurrences -I a -I api -c -o a/Shared.cmo Shared.ml
  $ ocamlc -bin-annot -bin-annot-occurrences -I a -I api -c -o a/Relay.cmo Relay.ml
  $ ocamlc -bin-annot -bin-annot-occurrences -I a -I api -c a/Use_a.ml
  $ cp "$FIXTURE/b/Provider.ml" b/Provider.ml
  $ cp "$FIXTURE/b/Use_b.ml" b/Use_b.ml
  $ ocamlc -bin-annot -bin-annot-occurrences -intf-suffix .ml -I api -c b/Provider.ml
  $ ocamlc -bin-annot -bin-annot-occurrences -I b -I api -c -o b/Shared.cmo Shared.ml
  $ ocamlc -bin-annot -bin-annot-occurrences -I b -I api -c -o b/Relay.cmo Relay.ml
  $ ocamlc -bin-annot -bin-annot-occurrences -I b -I api -c b/Use_b.ml

  $ reanalyze.exe -ci -dce-cmt a > a.out 2>/dev/null
  $ grep -m1 -oF -- 'optional argument context of function Arg.+g is always supplied (1 calls)' a.out
  optional argument context of function Arg.+g is always supplied (1 calls)
  $ reanalyze.exe -ci -dce-cmt b > b.out 2>/dev/null
  $ grep -m1 -oF -- 'optional argument context of function Arg.+g is never used' b.out
  optional argument context of function Arg.+g is never used
  $ reanalyze.exe -ci -debug -dce-cmt . > all.out 2>/dev/null
  $ grep -m1 -oF -- 'optional argument context of function Arg.+g is always supplied (1 calls)' all.out
  optional argument context of function Arg.+g is always supplied (1 calls)
  $ grep -m1 -oF -- 'optional argument context of function Arg.+g is never used' all.out
  optional argument context of function Arg.+g is never used
  $ grep -m1 -oF -- 'optional argument context of function Partial_arg.+g is always supplied (1 calls)' all.out
  optional argument context of function Partial_arg.+g is always supplied (1 calls)
  $ grep -m1 -oF -- 'optional argument context of function Partial_arg.+g is never used' all.out
  optional argument context of function Partial_arg.+g is never used
  $ grep -m1 -oF -- 'optional argument context of function Packed_arg.+g is always supplied (1 calls)' all.out
  optional argument context of function Packed_arg.+g is always supplied (1 calls)
  $ grep -m1 -oF -- 'optional argument context of function Packed_arg.+g is never used' all.out
  optional argument context of function Packed_arg.+g is never used
  $ grep -m1 -oF -- 'optional argument context of function Relayed_arg.+g is always supplied (1 calls)' all.out
  optional argument context of function Relayed_arg.+g is always supplied (1 calls)
  $ grep -m1 -oF -- 'optional argument context of function Relayed_arg.+g is never used' all.out
  optional argument context of function Relayed_arg.+g is never used

Both Shared functor contexts must be scanned exactly once.

  $ grep -cE 'Scanning .*Shared\.cmt ' all.out
  2

Ordered implicit opens.

  $ cp "$FIXTURE/First.ml" First.ml
  $ cp "$FIXTURE/Second.ml" Second.ml
  $ cp "$FIXTURE/Opened.ml" Opened.ml
  $ ocamlc -bin-annot -bin-annot-occurrences -c First.ml
  $ ocamlc -bin-annot -bin-annot-occurrences -c Second.ml
  $ ocamlc -bin-annot -bin-annot-occurrences -open First -open Second -c -o a/Opened.cmo Opened.ml
  $ ocamlc -bin-annot -bin-annot-occurrences -open Second -open First -c -o b/Opened.cmo Opened.ml
  $ reanalyze.exe -ci -debug -dce-cmt . > opens.out 2>/dev/null
  $ grep -m1 -oF -- 'Live Value +First.+g' opens.out
  Live Value +First.+g
  $ grep -m1 -oF -- 'Dead Value +First.+g' opens.out
  [1]
  $ grep -m1 -oF -- 'Live Value +Second.+g' opens.out
  Live Value +Second.+g
  $ grep -m1 -oF -- 'Dead Value +Second.+g' opens.out
  [1]

Ordered -open contexts must each contribute one call.

  $ grep -cE 'Scanning .*Opened\.cmt ' opens.out
  2
  $ grep -cE 'optional argument opened of function \+g is always supplied \(1 calls\)' opens.out
  2

The same with an install copy of each context.

  $ mkdir a/install
  $ cp a/*.cmt a/install
  $ mkdir b/install
  $ cp b/*.cmt b/install
  $ reanalyze.exe -ci -debug -dce-cmt . > copies.out 2>/dev/null
  $ grep -m1 -oF -- 'optional argument context of function Arg.+g is always supplied (1 calls)' copies.out
  optional argument context of function Arg.+g is always supplied (1 calls)
  $ grep -m1 -oF -- 'optional argument context of function Arg.+g is never used' copies.out
  optional argument context of function Arg.+g is never used
  $ grep -m1 -oF -- 'optional argument context of function Partial_arg.+g is always supplied (1 calls)' copies.out
  optional argument context of function Partial_arg.+g is always supplied (1 calls)
  $ grep -m1 -oF -- 'optional argument context of function Partial_arg.+g is never used' copies.out
  optional argument context of function Partial_arg.+g is never used
  $ grep -m1 -oF -- 'optional argument context of function Packed_arg.+g is always supplied (1 calls)' copies.out
  optional argument context of function Packed_arg.+g is always supplied (1 calls)
  $ grep -m1 -oF -- 'optional argument context of function Packed_arg.+g is never used' copies.out
  optional argument context of function Packed_arg.+g is never used
  $ grep -m1 -oF -- 'optional argument context of function Relayed_arg.+g is always supplied (1 calls)' copies.out
  optional argument context of function Relayed_arg.+g is always supplied (1 calls)
  $ grep -m1 -oF -- 'optional argument context of function Relayed_arg.+g is never used' copies.out
  optional argument context of function Relayed_arg.+g is never used

Both Shared functor contexts must be scanned exactly once.

  $ grep -cE 'Scanning .*Shared\.cmt ' copies.out
  2

  $ grep -m1 -oF -- 'Live Value +First.+g' copies.out
  Live Value +First.+g
  $ grep -m1 -oF -- 'Dead Value +First.+g' copies.out
  [1]
  $ grep -m1 -oF -- 'Live Value +Second.+g' copies.out
  Live Value +Second.+g
  $ grep -m1 -oF -- 'Dead Value +Second.+g' copies.out
  [1]

Ordered -open contexts must each contribute one call.

  $ grep -cE 'Scanning .*Opened\.cmt ' copies.out
  2
  $ grep -cE 'optional argument opened of function \+g is always supplied \(1 calls\)' copies.out
  2

Native-only cross-unit functor imports: the native objects attribute calls
as the bytecode objects do.

  $ cp "$FIXTURE/Native_provider.ml" Native_provider.ml
  $ ocamlc -bin-annot -bin-annot-occurrences -I native_layout/byte -c -o native_layout/byte/Native_provider.cmo Native_provider.ml
  $ cp "$FIXTURE/Native_use.ml" Native_use.ml
  $ ocamlc -bin-annot -bin-annot-occurrences -I native_layout/byte -c -o native_layout/byte/Native_use.cmo Native_use.ml
  $ ocamlopt -bin-annot -bin-annot-occurrences -intf-suffix .ml -I native_layout/byte -I native_layout/native -c -o native_layout/native/Native_provider.cmx Native_provider.ml
  $ ocamlopt -bin-annot -bin-annot-occurrences -intf-suffix .ml -I native_layout/byte -I native_layout/native -c -o native_layout/native/Native_use.cmx Native_use.ml
  $ reanalyze.exe -ci -dce-cmt native_layout/byte > byte.out 2>/dev/null
  $ grep -m1 -oF -- 'optional argument native of function Arg.+g is always supplied (1 calls)' byte.out
  optional argument native of function Arg.+g is always supplied (1 calls)
  $ reanalyze.exe -ci -dce-cmt native_layout/native > native.out 2>/dev/null
  $ cmp byte.out native.out
  $ reanalyze.exe -ci -dce-cmt native_layout > native_layout.out 2>/dev/null
  $ cmp byte.out native_layout.out

Bounded analysis of recursive module aliases.

  $ cp "$FIXTURE/Safe_alias.ml" Safe_alias.ml
  $ ocamlc -bin-annot -bin-annot-occurrences -o Safe_alias.exe Safe_alias.ml
  $ ./Safe_alias.exe > /dev/null
  $ reanalyze.exe -ci -dce-cmt Safe_alias.cmt > Safe_alias.out 2>/dev/null
  $ grep -m1 -oF -- 'Analysis reported 0 issues' Safe_alias.out
  Analysis reported 0 issues

  $ cp "$FIXTURE/Nested_alias.ml" Nested_alias.ml
  $ ocamlc -bin-annot -bin-annot-occurrences -o Nested_alias.exe Nested_alias.ml
  $ ./Nested_alias.exe > /dev/null
  $ reanalyze.exe -ci -dce-cmt Nested_alias.cmt > Nested_alias.out 2>/dev/null
  $ grep -m1 -oF -- 'Analysis reported 0 issues' Nested_alias.out
  Analysis reported 0 issues
