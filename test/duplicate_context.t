An identical source compiled against two distinct dependency contexts.

  $ FIXTURE=../examples/regression/duplicate_context
  $ cp "$FIXTURE/Shared.ml" Shared.ml
  $ mkdir a
  $ cp "$FIXTURE/a/Provider.ml" a/Provider.ml
  $ ocamlc -bin-annot -bin-annot-occurrences -c a/Provider.ml
  $ ocamlc -bin-annot -bin-annot-occurrences -I a -c -o a/Shared.cmo Shared.ml
  $ mkdir b
  $ cp "$FIXTURE/b/Provider.ml" b/Provider.ml
  $ ocamlc -bin-annot -bin-annot-occurrences -c b/Provider.ml
  $ ocamlc -bin-annot -bin-annot-occurrences -I b -c -o b/Shared.cmo Shared.ml

Both dependency contexts must be scanned exactly once, both dependency
implementations must remain live, and each dependency context must receive
exactly one call.

  $ reanalyze.exe -ci -debug -dce-cmt . > contexts.out 2>/dev/null
  $ grep -cE 'Scanning .*Shared\.cmt ' contexts.out
  2
  $ grep -cE 'Live Value \+Provider\.\+g:' contexts.out
  2
  $ grep -cE 'optional argument x of function \+g is always supplied \(1 calls\)' contexts.out
  2
  $ grep -m1 -oF -- 'Dead Value +Provider.+g' contexts.out
  [1]

The same with an install copy of each context.

  $ mkdir a/install b/install
  $ cp a/Provider.cmt a/Shared.cmt a/install
  $ cp b/Provider.cmt b/Shared.cmt b/install
  $ reanalyze.exe -ci -debug -dce-cmt . > copies.out 2>/dev/null
  $ grep -cE 'Scanning .*Shared\.cmt ' copies.out
  2
  $ grep -cE 'Live Value \+Provider\.\+g:' copies.out
  2
  $ grep -cE 'optional argument x of function \+g is always supplied \(1 calls\)' copies.out
  2
  $ grep -m1 -oF -- 'Dead Value +Provider.+g' copies.out
  [1]
