A split interface: the .cmti, the implementation .cmt and its consumer in
separate directories, in several layouts.

  $ FIXTURE=../examples/regression/compilation_context
  $ mkdir src api objects consumer
  $ cp "$FIXTURE/Split.mli" src/Split.mli
  $ cp "$FIXTURE/Split.ml" src/Split.ml
  $ cp "$FIXTURE/Split_use.ml" src/Split_use.ml
  $ ocamlc -bin-annot -bin-annot-occurrences -c -o api/Split.cmi src/Split.mli
  $ ocamlc -bin-annot -bin-annot-occurrences -intf-suffix .ml -I api -c -o objects/Split.cmo src/Split.ml
  $ ocamlc -bin-annot -bin-annot-occurrences -I api -I objects -c -o consumer/Split_use.cmo src/Split_use.ml

Layout colocated.

  $ mkdir -p layouts/colocated/all && cp api/Split.cmti layouts/colocated/all
  $ mkdir -p layouts/colocated/all && cp objects/Split.cmt layouts/colocated/all
  $ mkdir -p layouts/colocated/all && cp consumer/Split_use.cmt layouts/colocated/all
  $ reanalyze.exe -ci -debug -dce-cmt "$PWD/layouts/colocated" > colocated.out 2>/dev/null
  $ grep -m1 -oF -- 'Live Value +Split.Used.+g' colocated.out
  Live Value +Split.Used.+g
  $ grep -m1 -oF -- 'Dead Value +Split.Unused.+g' colocated.out
  Dead Value +Split.Unused.+g
  $ grep -m1 -oF -- 'optional argument split of function Used.+g is always supplied (1 calls)' colocated.out
  optional argument split of function Used.+g is always supplied (1 calls)
  $ grep -m1 -oF -- 'Dead Value +Split.Used.+g' colocated.out
  [1]

Layout separate.

  $ mkdir -p layouts/separate/api && cp api/Split.cmti layouts/separate/api
  $ mkdir -p layouts/separate/objects && cp objects/Split.cmt layouts/separate/objects
  $ mkdir -p layouts/separate/consumer && cp consumer/Split_use.cmt layouts/separate/consumer
  $ reanalyze.exe -ci -debug -dce-cmt "$PWD/layouts/separate" > separate.out 2>/dev/null
  $ grep -m1 -oF -- 'Live Value +Split.Used.+g' separate.out
  Live Value +Split.Used.+g
  $ grep -m1 -oF -- 'Dead Value +Split.Unused.+g' separate.out
  Dead Value +Split.Unused.+g
  $ grep -m1 -oF -- 'optional argument split of function Used.+g is always supplied (1 calls)' separate.out
  optional argument split of function Used.+g is always supplied (1 calls)
  $ grep -m1 -oF -- 'Dead Value +Split.Used.+g' separate.out
  [1]

Layout consumer-with-api.

  $ mkdir -p layouts/consumer-with-api/api && cp api/Split.cmti layouts/consumer-with-api/api
  $ mkdir -p layouts/consumer-with-api/objects && cp objects/Split.cmt layouts/consumer-with-api/objects
  $ mkdir -p layouts/consumer-with-api/api && cp consumer/Split_use.cmt layouts/consumer-with-api/api
  $ reanalyze.exe -ci -debug -dce-cmt "$PWD/layouts/consumer-with-api" > consumer-with-api.out 2>/dev/null
  $ grep -m1 -oF -- 'Live Value +Split.Used.+g' consumer-with-api.out
  Live Value +Split.Used.+g
  $ grep -m1 -oF -- 'Dead Value +Split.Unused.+g' consumer-with-api.out
  Dead Value +Split.Unused.+g
  $ grep -m1 -oF -- 'optional argument split of function Used.+g is always supplied (1 calls)' consumer-with-api.out
  optional argument split of function Used.+g is always supplied (1 calls)
  $ grep -m1 -oF -- 'Dead Value +Split.Used.+g' consumer-with-api.out
  [1]

Layout consumer-with-implementation.

  $ mkdir -p layouts/consumer-with-implementation/api && cp api/Split.cmti layouts/consumer-with-implementation/api
  $ mkdir -p layouts/consumer-with-implementation/objects && cp objects/Split.cmt layouts/consumer-with-implementation/objects
  $ mkdir -p layouts/consumer-with-implementation/objects && cp consumer/Split_use.cmt layouts/consumer-with-implementation/objects
  $ reanalyze.exe -ci -debug -dce-cmt "$PWD/layouts/consumer-with-implementation" > consumer-with-implementation.out 2>/dev/null
  $ grep -m1 -oF -- 'Live Value +Split.Used.+g' consumer-with-implementation.out
  Live Value +Split.Used.+g
  $ grep -m1 -oF -- 'Dead Value +Split.Unused.+g' consumer-with-implementation.out
  Dead Value +Split.Unused.+g
  $ grep -m1 -oF -- 'optional argument split of function Used.+g is always supplied (1 calls)' consumer-with-implementation.out
  optional argument split of function Used.+g is always supplied (1 calls)
  $ grep -m1 -oF -- 'Dead Value +Split.Used.+g' consumer-with-implementation.out
  [1]

Layout separate-copies.

  $ mkdir -p layouts/separate-copies/api && cp api/Split.cmti layouts/separate-copies/api
  $ mkdir -p layouts/separate-copies/objects && cp objects/Split.cmt layouts/separate-copies/objects
  $ mkdir -p layouts/separate-copies/consumer && cp consumer/Split_use.cmt layouts/separate-copies/consumer
  $ mkdir -p layouts/separate-copies/install/api && cp api/Split.cmti layouts/separate-copies/install/api
  $ mkdir -p layouts/separate-copies/install/objects && cp objects/Split.cmt layouts/separate-copies/install/objects
  $ mkdir -p layouts/separate-copies/install/consumer && cp consumer/Split_use.cmt layouts/separate-copies/install/consumer
  $ reanalyze.exe -ci -debug -dce-cmt "$PWD/layouts/separate-copies" > separate-copies.out 2>/dev/null
  $ grep -m1 -oF -- 'Live Value +Split.Used.+g' separate-copies.out
  Live Value +Split.Used.+g
  $ grep -m1 -oF -- 'Dead Value +Split.Unused.+g' separate-copies.out
  Dead Value +Split.Unused.+g
  $ grep -m1 -oF -- 'optional argument split of function Used.+g is always supplied (1 calls)' separate-copies.out
  optional argument split of function Used.+g is always supplied (1 calls)
  $ grep -m1 -oF -- 'Dead Value +Split.Used.+g' separate-copies.out
  [1]

A second distinct implementation of the same API is still ambiguous:
do not arbitrarily pick one just because a split pair is now allowed.

  $ cp "$FIXTURE/Split.ml" src/Split_other.ml
  $ mkdir -p layouts/ambiguous/api && cp api/Split.cmti layouts/ambiguous/api
  $ mkdir -p layouts/ambiguous/objects && cp objects/Split.cmt layouts/ambiguous/objects
  $ mkdir -p layouts/ambiguous/consumer && cp consumer/Split_use.cmt layouts/ambiguous/consumer
  $ mkdir layouts/ambiguous/other
  $ ocamlc -bin-annot -bin-annot-occurrences -intf-suffix .ml -I api -c -o "$PWD/layouts/ambiguous/other/Split.cmo" src/Split_other.ml
  $ reanalyze.exe -ci -debug -dce-cmt "$PWD/layouts/ambiguous" > ambiguous.out 2>/dev/null
  $ grep -m1 -oF -- 'Live Value +Split.Used.+g' ambiguous.out
  Live Value +Split.Used.+g
  $ grep -m1 -oF -- 'Live Value +Split.Unused.+g' ambiguous.out
  Live Value +Split.Unused.+g
  $ grep -m1 -oF -- 'Live Value +Split_other.Used.+g' ambiguous.out
  Live Value +Split_other.Used.+g
  $ grep -m1 -oF -- 'Live Value +Split_other.Unused.+g' ambiguous.out
  Live Value +Split_other.Unused.+g
