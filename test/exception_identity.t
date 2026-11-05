Exception identity through module aliases, interfaces, wrappers, dependency
contexts and import digests. Each scenario lives in its own directory.

  $ ROOT=$PWD

Case local.

  $ mkdir -p local
  $ cd "$ROOT/local"
  $ cat > left.ml <<'EOF'
  > exception Used = Not_found
  > EOF
  $ ocamlc -w -a -bin-annot -c "$PWD/left.ml"
  $ cat > right.ml <<'EOF'
  > exception Used = Not_found
  > EOF
  $ ocamlc -w -a -bin-annot -c "$PWD/right.ml"
  $ : > a.ml
  $ ocamlc -w -a -bin-annot -c "$PWD/a.ml"
  $ cat > use.ml <<'EOF'
  > module Left = Right
  > let () = raise Left.Used
  > EOF
  $ ocamlc -w -a -bin-annot -c "$PWD/use.ml"
  $ reanalyze.exe -ci -debug -native-build-target . -dce-cmt . > analysis.out 2>/dev/null
  $ grep -m1 -oF -- 'Live Exception +right.Used:' analysis.out
  Live Exception +right.Used:
  $ grep -m1 -oF -- 'Dead Exception +right.Used:' analysis.out
  [1]
  $ grep -m1 -oF -- 'Dead Exception +left.Used:' analysis.out
  Dead Exception +left.Used:
  $ grep -m1 -oF -- 'Live Exception +left.Used:' analysis.out
  [1]

Case let-local.

  $ mkdir -p ../let-local
  $ cd "$ROOT/let-local"
  $ cat > left.ml <<'EOF'
  > exception Used = Not_found
  > EOF
  $ ocamlc -w -a -bin-annot -c "$PWD/left.ml"
  $ cat > right.ml <<'EOF'
  > exception Used = Not_found
  > EOF
  $ ocamlc -w -a -bin-annot -c "$PWD/right.ml"
  $ : > a.ml
  $ ocamlc -w -a -bin-annot -c "$PWD/a.ml"
  $ cat > use.ml <<'EOF'
  > let () = let module Left = Right in raise Left.Used
  > EOF
  $ ocamlc -w -a -bin-annot -c "$PWD/use.ml"
  $ reanalyze.exe -ci -debug -native-build-target . -dce-cmt . > analysis.out 2>/dev/null
  $ grep -m1 -oF -- 'Live Exception +right.Used:' analysis.out
  Live Exception +right.Used:
  $ grep -m1 -oF -- 'Dead Exception +right.Used:' analysis.out
  [1]
  $ grep -m1 -oF -- 'Dead Exception +left.Used:' analysis.out
  Dead Exception +left.Used:
  $ grep -m1 -oF -- 'Live Exception +left.Used:' analysis.out
  [1]

Case shadow-alias.

  $ mkdir -p ../shadow-alias
  $ cd "$ROOT/shadow-alias"
  $ cat > left.ml <<'EOF'
  > exception Used = Not_found
  > EOF
  $ ocamlc -w -a -bin-annot -c "$PWD/left.ml"
  $ cat > right.ml <<'EOF'
  > exception Used = Not_found
  > EOF
  $ ocamlc -w -a -bin-annot -c "$PWD/right.ml"
  $ cat > a.ml <<'EOF'
  > include struct module Alias = Left end
  > module Alias = Right
  > EOF
  $ ocamlc -w -a -bin-annot -c "$PWD/a.ml"
  $ cat > use.ml <<'EOF'
  > let () = raise A.Alias.Used
  > EOF
  $ ocamlc -w -a -bin-annot -c "$PWD/use.ml"
  $ reanalyze.exe -ci -debug -native-build-target . -dce-cmt . > analysis.out 2>/dev/null
  $ grep -m1 -oF -- 'Live Exception +right.Used:' analysis.out
  Live Exception +right.Used:
  $ grep -m1 -oF -- 'Dead Exception +right.Used:' analysis.out
  [1]
  $ grep -m1 -oF -- 'Dead Exception +left.Used:' analysis.out
  Dead Exception +left.Used:
  $ grep -m1 -oF -- 'Live Exception +left.Used:' analysis.out
  [1]

Case shadow-concrete.

  $ mkdir -p ../shadow-concrete
  $ cd "$ROOT/shadow-concrete"
  $ cat > left.ml <<'EOF'
  > exception Used = Not_found
  > EOF
  $ ocamlc -w -a -bin-annot -c "$PWD/left.ml"
  $ cat > right.ml <<'EOF'
  > exception Used = Not_found
  > EOF
  $ ocamlc -w -a -bin-annot -c "$PWD/right.ml"
  $ cat > a.ml <<'EOF'
  > include struct module Alias = Left end
  > module Alias = struct exception Used = Not_found end
  > EOF
  $ ocamlc -w -a -bin-annot -c "$PWD/a.ml"
  $ cat > use.ml <<'EOF'
  > let () = raise A.Alias.Used
  > EOF
  $ ocamlc -w -a -bin-annot -c "$PWD/use.ml"
  $ reanalyze.exe -ci -debug -native-build-target . -dce-cmt . > analysis.out 2>/dev/null
  $ grep -m1 -oF -- 'Live Exception +a.Alias.Used:' analysis.out
  Live Exception +a.Alias.Used:
  $ grep -m1 -oF -- 'Dead Exception +a.Alias.Used:' analysis.out
  [1]
  $ grep -m1 -oF -- 'Dead Exception +left.Used:' analysis.out
  Dead Exception +left.Used:
  $ grep -m1 -oF -- 'Live Exception +left.Used:' analysis.out
  [1]
  $ grep -m1 -oF -- 'Dead Exception +right.Used:' analysis.out
  Dead Exception +right.Used:
  $ grep -m1 -oF -- 'Live Exception +right.Used:' analysis.out
  [1]

Case saved.

  $ mkdir -p ../saved
  $ cd "$ROOT/saved"
  $ cat > left.ml <<'EOF'
  > exception Used = Not_found
  > EOF
  $ ocamlc -w -a -bin-annot -c "$PWD/left.ml"
  $ cat > right.ml <<'EOF'
  > exception Used = Not_found
  > EOF
  $ ocamlc -w -a -bin-annot -c "$PWD/right.ml"
  $ cat > a.ml <<'EOF'
  > module Source = struct exception Used = Not_found end
  > include struct module Alias = Source end
  > module Saved = Alias
  > module Alias = struct exception Used = Not_found end
  > EOF
  $ ocamlc -w -a -bin-annot -c "$PWD/a.ml"
  $ cat > use.ml <<'EOF'
  > let () = raise A.Saved.Used
  > EOF
  $ ocamlc -w -a -bin-annot -c "$PWD/use.ml"
  $ reanalyze.exe -ci -debug -native-build-target . -dce-cmt . > analysis.out 2>/dev/null
  $ grep -m1 -oF -- 'Live Exception +a.Source.Used:' analysis.out
  Live Exception +a.Source.Used:
  $ grep -m1 -oF -- 'Dead Exception +a.Source.Used:' analysis.out
  [1]
  $ grep -m1 -oF -- 'Dead Exception +a.Alias.Used:' analysis.out
  Dead Exception +a.Alias.Used:
  $ grep -m1 -oF -- 'Live Exception +a.Alias.Used:' analysis.out
  [1]
  $ grep -m1 -oF -- 'Dead Exception +left.Used:' analysis.out
  Dead Exception +left.Used:
  $ grep -m1 -oF -- 'Live Exception +left.Used:' analysis.out
  [1]
  $ grep -m1 -oF -- 'Dead Exception +right.Used:' analysis.out
  Dead Exception +right.Used:
  $ grep -m1 -oF -- 'Live Exception +right.Used:' analysis.out
  [1]

Case saved-and-replaced.

  $ mkdir -p ../saved-and-replaced
  $ cd "$ROOT/saved-and-replaced"
  $ cat > left.ml <<'EOF'
  > exception Used = Not_found
  > EOF
  $ ocamlc -w -a -bin-annot -c "$PWD/left.ml"
  $ cat > right.ml <<'EOF'
  > exception Used = Not_found
  > EOF
  $ ocamlc -w -a -bin-annot -c "$PWD/right.ml"
  $ cat > a.ml <<'EOF'
  > module Source = struct exception Used = Not_found end
  > include struct module Alias = Source end
  > module Saved = Alias
  > module Alias = struct exception Used = Not_found end
  > EOF
  $ ocamlc -w -a -bin-annot -c "$PWD/a.ml"
  $ cat > use.ml <<'EOF'
  > let () = (try raise A.Saved.Used with _ -> ()); raise A.Alias.Used
  > EOF
  $ ocamlc -w -a -bin-annot -c "$PWD/use.ml"
  $ reanalyze.exe -ci -debug -native-build-target . -dce-cmt . > analysis.out 2>/dev/null
  $ grep -m1 -oF -- 'Live Exception +a.Source.Used:' analysis.out
  Live Exception +a.Source.Used:
  $ grep -m1 -oF -- 'Dead Exception +a.Source.Used:' analysis.out
  [1]
  $ grep -m1 -oF -- 'Live Exception +a.Alias.Used:' analysis.out
  Live Exception +a.Alias.Used:
  $ grep -m1 -oF -- 'Dead Exception +a.Alias.Used:' analysis.out
  [1]
  $ grep -m1 -oF -- 'Dead Exception +left.Used:' analysis.out
  Dead Exception +left.Used:
  $ grep -m1 -oF -- 'Live Exception +left.Used:' analysis.out
  [1]
  $ grep -m1 -oF -- 'Dead Exception +right.Used:' analysis.out
  Dead Exception +right.Used:
  $ grep -m1 -oF -- 'Live Exception +right.Used:' analysis.out
  [1]

An interface-only provider can forward an explicit alias to a scanned
implementation, without importing that provider's implementation CMT.

  $ mkdir -p ../interface-only
  $ cd "$ROOT/interface-only"
  $ cat > source.ml <<'EOF'
  > exception Used = Not_found
  > exception Unused = Not_found
  > EOF
  $ ocamlc -w -a -bin-annot -c "$PWD/source.ml"
  $ cat > wrapper.mli <<'EOF'
  > module Alias = Source
  > EOF
  $ ocamlc -w -a -bin-annot -c "$PWD/wrapper.mli"
  $ cat > wrapper.ml <<'EOF'
  > module Alias = Source
  > EOF
  $ ocamlc -w -a -bin-annot -c "$PWD/wrapper.ml"
  $ cat > use.ml <<'EOF'
  > let () = raise Wrapper.Alias.Used
  > EOF
  $ ocamlc -w -a -bin-annot -c "$PWD/use.ml"
  $ mkdir -p scan
  $ cp source.cmt scan
  $ cp wrapper.cmti scan
  $ cp use.cmt scan
  $ reanalyze.exe -ci -debug -native-build-target . -dce-cmt "$ROOT/interface-only/scan" > scan.out 2>/dev/null
  $ grep -m1 -oF -- 'Live Exception +source.Used:' scan.out
  Live Exception +source.Used:
  $ grep -m1 -oF -- 'Dead Exception +source.Used:' scan.out
  [1]
  $ grep -m1 -oF -- 'Dead Exception +source.Unused:' scan.out
  Dead Exception +source.Unused:
  $ grep -m1 -oF -- 'Live Exception +source.Unused:' scan.out
  [1]

A matching interface and implementation can live in separate directories.
A sibling of one kind must not hide the other, including install copies.

Layout separate.

  $ mkdir -p separate/api
  $ cp wrapper.cmti separate/api
  $ mkdir -p separate/objects
  $ cp wrapper.cmt separate/objects
  $ mkdir -p separate/consumer
  $ cp source.cmt separate/consumer
  $ cp use.cmt separate/consumer
  $ reanalyze.exe -ci -debug -native-build-target . -dce-cmt "$ROOT/interface-only/separate" > separate.out 2>/dev/null
  $ grep -m1 -oF -- 'Live Exception +source.Used:' separate.out
  Live Exception +source.Used:
  $ grep -m1 -oF -- 'Dead Exception +source.Used:' separate.out
  [1]
  $ grep -m1 -oF -- 'Dead Exception +source.Unused:' separate.out
  Dead Exception +source.Unused:
  $ grep -m1 -oF -- 'Live Exception +source.Unused:' separate.out
  [1]

Layout with-interface.

  $ mkdir -p with-interface/api
  $ cp wrapper.cmti with-interface/api
  $ mkdir -p with-interface/objects
  $ cp wrapper.cmt with-interface/objects
  $ cp source.cmt with-interface/api
  $ cp use.cmt with-interface/api
  $ reanalyze.exe -ci -debug -native-build-target . -dce-cmt "$ROOT/interface-only/with-interface" > with-interface.out 2>/dev/null
  $ grep -m1 -oF -- 'Live Exception +source.Used:' with-interface.out
  Live Exception +source.Used:
  $ grep -m1 -oF -- 'Dead Exception +source.Used:' with-interface.out
  [1]
  $ grep -m1 -oF -- 'Dead Exception +source.Unused:' with-interface.out
  Dead Exception +source.Unused:
  $ grep -m1 -oF -- 'Live Exception +source.Unused:' with-interface.out
  [1]

Layout with-implementation.

  $ mkdir -p with-implementation/api
  $ cp wrapper.cmti with-implementation/api
  $ mkdir -p with-implementation/objects
  $ cp wrapper.cmt with-implementation/objects
  $ cp source.cmt with-implementation/objects
  $ cp use.cmt with-implementation/objects
  $ reanalyze.exe -ci -debug -native-build-target . -dce-cmt "$ROOT/interface-only/with-implementation" > with-implementation.out 2>/dev/null
  $ grep -m1 -oF -- 'Live Exception +source.Used:' with-implementation.out
  Live Exception +source.Used:
  $ grep -m1 -oF -- 'Dead Exception +source.Used:' with-implementation.out
  [1]
  $ grep -m1 -oF -- 'Dead Exception +source.Unused:' with-implementation.out
  Dead Exception +source.Unused:
  $ grep -m1 -oF -- 'Live Exception +source.Unused:' with-implementation.out
  [1]

Layout separate-copies.

  $ mkdir -p separate-copies/api
  $ cp wrapper.cmti separate-copies/api
  $ mkdir -p separate-copies/objects
  $ cp wrapper.cmt separate-copies/objects
  $ mkdir -p separate-copies/consumer
  $ cp source.cmt separate-copies/consumer
  $ cp use.cmt separate-copies/consumer
  $ mkdir -p separate-copies/install/api
  $ cp wrapper.cmti separate-copies/install/api
  $ mkdir -p separate-copies/install/objects
  $ cp wrapper.cmt separate-copies/install/objects
  $ mkdir -p separate-copies/install/consumer
  $ cp source.cmt separate-copies/install/consumer
  $ cp use.cmt separate-copies/install/consumer
  $ reanalyze.exe -ci -debug -native-build-target . -dce-cmt "$ROOT/interface-only/separate-copies" > separate-copies.out 2>/dev/null
  $ grep -m1 -oF -- 'Live Exception +source.Used:' separate-copies.out
  Live Exception +source.Used:
  $ grep -m1 -oF -- 'Dead Exception +source.Used:' separate-copies.out
  [1]
  $ grep -m1 -oF -- 'Dead Exception +source.Unused:' separate-copies.out
  Dead Exception +source.Unused:
  $ grep -m1 -oF -- 'Live Exception +source.Unused:' separate-copies.out
  [1]

Unwrapped identifiers can infer forwarding children before a constraint
exposes more specific aliases. Retain those aliases without the provider.

  $ mkdir -p ../unwrapped-include
  $ cd "$ROOT/unwrapped-include"
  $ cat > exn.ml <<'EOF'
  > exception Used = Not_found
  > exception Unused = Not_found
  > EOF
  $ ocamlc -w -a -bin-annot -c "$PWD/exn.ml"
  $ cat > exports.ml <<'EOF'
  > module Nested = struct module Alias = Exn end
  > EOF
  $ ocamlc -w -a -bin-annot -c "$PWD/exports.ml"
  $ cat > constrained.ml <<'EOF'
  > include (Exports : sig module Nested : sig module Alias = Exn end end)
  > EOF
  $ ocamlc -w -a -bin-annot -c "$PWD/constrained.ml"
  $ cat > use.ml <<'EOF'
  > let () = raise Constrained.Nested.Alias.Used
  > EOF
  $ ocamlc -w -a -bin-annot -c "$PWD/use.ml"
  $ mkdir -p scan
  $ cp exn.cmt scan
  $ cp constrained.cmt scan
  $ cp use.cmt scan
  $ reanalyze.exe -ci -debug -native-build-target . -dce-cmt "$ROOT/unwrapped-include/scan" > scan.out 2>/dev/null
  $ grep -m1 -oF -- 'Live Exception +exn.Used:' scan.out
  Live Exception +exn.Used:
  $ grep -m1 -oF -- 'Dead Exception +exn.Used:' scan.out
  [1]
  $ grep -m1 -oF -- 'Dead Exception +exn.Unused:' scan.out
  Dead Exception +exn.Unused:
  $ grep -m1 -oF -- 'Live Exception +exn.Unused:' scan.out
  [1]

Re-entering a wrapper through B.A.X after A.X is finite, even though
the new field list ends with the entire previous field list.

  $ mkdir -p ../growing-wrapper
  $ cd "$ROOT/growing-wrapper"
  $ cat > dune-project <<'EOF'
  > (lang dune 2.0)
  > (name growing_exception_wrapper)
  > EOF
  $ cat > dune <<'EOF'
  > (executable (name main) (flags (:standard -w -a)))
  > EOF
  $ cat > b.ml <<'EOF'
  > module A = struct module X = struct exception Used = Not_found exception Unused = Not_found end end
  > EOF
  $ cat > a.ml <<'EOF'
  > module X = B.A.X
  > EOF
  $ cat > main.ml <<'EOF'
  > let () = try raise A.X.Used with _ -> ()
  > EOF
  $ dune build --root . @check 2>&1
  $ reanalyze.exe -ci -debug -native-build-target . -dce-cmt _build/default > analysis.out 2>/dev/null
  $ grep -m1 -oF -- 'Live Exception +b.A.X.Used:' analysis.out
  Live Exception +b.A.X.Used:
  $ grep -m1 -oF -- 'Dead Exception +b.A.X.Used:' analysis.out
  [1]
  $ grep -m1 -oF -- 'Dead Exception +b.A.X.Unused:' analysis.out
  Dead Exception +b.A.X.Unused:
  $ grep -m1 -oF -- 'Live Exception +b.A.X.Unused:' analysis.out
  [1]

The scanner distinguishes identical sources built against different
dependencies. Exception resolution must retain both consumer contexts.

  $ mkdir -p ../contexts
  $ cd "$ROOT/contexts"
  $ cat > left.ml <<'EOF'
  > exception Used = Not_found
  > exception Unused = Not_found
  > EOF
  $ ocamlc -w -a -bin-annot -c "$PWD/left.ml"
  $ cat > right.ml <<'EOF'
  > exception Used = Not_found
  > exception Unused = Not_found
  > EOF
  $ ocamlc -w -a -bin-annot -c "$PWD/right.ml"
  $ mkdir -p a
  $ cd "$ROOT/contexts/a"
  $ cat > provider.ml <<'EOF'
  > module Alias = Left
  > EOF
  $ ocamlc -w -a -bin-annot -I "$ROOT/contexts" -c "$PWD/provider.ml"
  $ mkdir -p ../b
  $ cd "$ROOT/contexts/b"
  $ cat > provider.ml <<'EOF'
  > module Alias = Right
  > EOF
  $ ocamlc -w -a -bin-annot -I "$ROOT/contexts" -c "$PWD/provider.ml"
  $ cd "$ROOT/contexts"
  $ cat > shared.ml <<'EOF'
  > let () = raise Provider.Alias.Used
  > EOF
  $ ocamlc -bin-annot -I a -c -o a/shared.cmo "$ROOT/contexts/shared.ml"
  $ ocamlc -bin-annot -I b -c -o b/shared.cmo "$ROOT/contexts/shared.ml"
  $ reanalyze.exe -ci -debug -native-build-target . -dce-cmt . > analysis.out 2>/dev/null
  $ grep -m1 -oF -- 'Live Exception +left.Used:' analysis.out
  Live Exception +left.Used:
  $ grep -m1 -oF -- 'Dead Exception +left.Used:' analysis.out
  [1]
  $ grep -m1 -oF -- 'Live Exception +right.Used:' analysis.out
  Live Exception +right.Used:
  $ grep -m1 -oF -- 'Dead Exception +right.Used:' analysis.out
  [1]
  $ grep -m1 -oF -- 'Dead Exception +left.Unused:' analysis.out
  Dead Exception +left.Unused:
  $ grep -m1 -oF -- 'Live Exception +left.Unused:' analysis.out
  [1]
  $ grep -m1 -oF -- 'Dead Exception +right.Unused:' analysis.out
  Dead Exception +right.Unused:
  $ grep -m1 -oF -- 'Live Exception +right.Unused:' analysis.out
  [1]

Each exception consumer context is scanned once.

  $ grep -cE 'Scanning .*shared\.cmt ' analysis.out
  2

The same with an install copy of each context.

  $ mkdir -p a/install
  $ cp a/provider.cmt a/install
  $ cp a/shared.cmt a/install
  $ mkdir -p b/install
  $ cp b/provider.cmt b/install
  $ cp b/shared.cmt b/install
  $ reanalyze.exe -ci -debug -native-build-target . -dce-cmt . > copies.out 2>/dev/null
  $ grep -m1 -oF -- 'Live Exception +left.Used:' copies.out
  Live Exception +left.Used:
  $ grep -m1 -oF -- 'Dead Exception +left.Used:' copies.out
  [1]
  $ grep -m1 -oF -- 'Live Exception +right.Used:' copies.out
  Live Exception +right.Used:
  $ grep -m1 -oF -- 'Dead Exception +right.Used:' copies.out
  [1]
  $ grep -m1 -oF -- 'Dead Exception +left.Unused:' copies.out
  Dead Exception +left.Unused:
  $ grep -m1 -oF -- 'Live Exception +left.Unused:' copies.out
  [1]
  $ grep -m1 -oF -- 'Dead Exception +right.Unused:' copies.out
  Dead Exception +right.Unused:
  $ grep -m1 -oF -- 'Live Exception +right.Unused:' copies.out
  [1]

Each exception consumer context is scanned once.

  $ grep -cE 'Scanning .*shared\.cmt ' copies.out
  2

Ordered implicit opens can change a local alias target while leaving
the source and imported interfaces identical. Keep both lexical graphs.

  $ mkdir -p ../ordered-open-contexts
  $ cd "$ROOT/ordered-open-contexts"
  $ cat > left.ml <<'EOF'
  > exception Used = Not_found
  > exception Unused = Not_found
  > EOF
  $ ocamlc -w -a -bin-annot -c "$PWD/left.ml"
  $ cat > right.ml <<'EOF'
  > exception Used = Not_found
  > exception Unused = Not_found
  > EOF
  $ ocamlc -w -a -bin-annot -c "$PWD/right.ml"
  $ cat > first.ml <<'EOF'
  > module Target = Left
  > EOF
  $ ocamlc -w -a -bin-annot -c "$PWD/first.ml"
  $ cat > second.ml <<'EOF'
  > module Target = Right
  > EOF
  $ ocamlc -w -a -bin-annot -c "$PWD/second.ml"
  $ cat > shared.ml <<'EOF'
  > let run () = let module Alias = Target in raise Alias.Used
  > let () = run ()
  > EOF
  $ mkdir -p a
  $ ocamlc -bin-annot -open First -open Second -c -o a/shared.cmo "$ROOT/ordered-open-contexts/shared.ml"
  $ mkdir -p b
  $ ocamlc -bin-annot -open Second -open First -c -o b/shared.cmo "$ROOT/ordered-open-contexts/shared.ml"
  $ reanalyze.exe -ci -debug -native-build-target . -dce-cmt . > analysis.out 2>/dev/null
  $ grep -m1 -oF -- 'Live Exception +left.Used:' analysis.out
  Live Exception +left.Used:
  $ grep -m1 -oF -- 'Dead Exception +left.Used:' analysis.out
  [1]
  $ grep -m1 -oF -- 'Live Exception +right.Used:' analysis.out
  Live Exception +right.Used:
  $ grep -m1 -oF -- 'Dead Exception +right.Used:' analysis.out
  [1]
  $ grep -m1 -oF -- 'Dead Exception +left.Unused:' analysis.out
  Dead Exception +left.Unused:
  $ grep -m1 -oF -- 'Live Exception +left.Unused:' analysis.out
  [1]
  $ grep -m1 -oF -- 'Dead Exception +right.Unused:' analysis.out
  Dead Exception +right.Unused:
  $ grep -m1 -oF -- 'Live Exception +right.Unused:' analysis.out
  [1]

Identical provider sources can also have equal interface digests but
distinct imports. Without a matching sibling, do not choose either one.

  $ mkdir -p ../ambiguous-provider-contexts
  $ cd "$ROOT/ambiguous-provider-contexts"
  $ cat > left.ml <<'EOF'
  > exception Used = Not_found
  > EOF
  $ ocamlc -w -a -bin-annot -c "$PWD/left.ml"
  $ cat > right.ml <<'EOF'
  > exception Used = Not_found
  > EOF
  $ ocamlc -w -a -bin-annot -c "$PWD/right.ml"
  $ mkdir -p a
  $ cd "$ROOT/ambiguous-provider-contexts/a"
  $ cat > provider.ml <<'EOF'
  > module Target = Left
  > EOF
  $ ocamlc -w -a -bin-annot -I "$ROOT/ambiguous-provider-contexts" -c "$PWD/provider.ml"
  $ mkdir -p ../b
  $ cd "$ROOT/ambiguous-provider-contexts/b"
  $ cat > provider.ml <<'EOF'
  > module Target = Right
  > EOF
  $ ocamlc -w -a -bin-annot -I "$ROOT/ambiguous-provider-contexts" -c "$PWD/provider.ml"
  $ cd "$ROOT/ambiguous-provider-contexts"
  $ cat > shared.ml <<'EOF'
  > module Alias = Provider.Target
  > EOF
  $ ocamlc -bin-annot -I a -c -o a/shared.cmo "$ROOT/ambiguous-provider-contexts/shared.ml"
  $ ocamlc -bin-annot -I b -c -o b/shared.cmo "$ROOT/ambiguous-provider-contexts/shared.ml"
  $ cat > use.ml <<'EOF'
  > let () = raise Shared.Alias.Used
  > EOF
  $ ocamlc -w -a -bin-annot -I "$ROOT/ambiguous-provider-contexts/b" -c "$PWD/use.ml"

Scan root order-false.

  $ mkdir -p order-false/a
  $ mkdir -p order-false/b
  $ mkdir -p order-false/consumer
  $ cp left.cmt order-false/consumer
  $ cp right.cmt order-false/consumer
  $ cp use.cmt order-false/consumer
  $ cp a/provider.cmt order-false/a
  $ cp a/shared.cmt order-false/a
  $ cp b/provider.cmt order-false/b
  $ cp b/shared.cmt order-false/b
  $ reanalyze.exe -ci -debug -native-build-target . -dce-cmt "$ROOT/ambiguous-provider-contexts/order-false" > order-false.out 2>/dev/null
  $ grep -m1 -oF -- 'Dead Exception +left.Used:' order-false.out
  Dead Exception +left.Used:
  $ grep -m1 -oF -- 'Live Exception +left.Used:' order-false.out
  [1]
  $ grep -m1 -oF -- 'Dead Exception +right.Used:' order-false.out
  Dead Exception +right.Used:
  $ grep -m1 -oF -- 'Live Exception +right.Used:' order-false.out
  [1]

Scan root order-true: a's provider and shared in b, b's in a.

  $ mkdir -p order-true/a
  $ mkdir -p order-true/b
  $ mkdir -p order-true/consumer
  $ cp left.cmt order-true/consumer
  $ cp right.cmt order-true/consumer
  $ cp use.cmt order-true/consumer
  $ cp a/provider.cmt order-true/b
  $ cp a/shared.cmt order-true/b
  $ cp b/provider.cmt order-true/a
  $ cp b/shared.cmt order-true/a
  $ reanalyze.exe -ci -debug -native-build-target . -dce-cmt "$ROOT/ambiguous-provider-contexts/order-true" > order-true.out 2>/dev/null
  $ grep -m1 -oF -- 'Dead Exception +left.Used:' order-true.out
  Dead Exception +left.Used:
  $ grep -m1 -oF -- 'Live Exception +left.Used:' order-true.out
  [1]
  $ grep -m1 -oF -- 'Dead Exception +right.Used:' order-true.out
  Dead Exception +right.Used:
  $ grep -m1 -oF -- 'Live Exception +right.Used:' order-true.out
  [1]

The consumer imports one Foo, and Foo in turn imports its own Target.
A same-named sibling with a conflicting digest must never win, even
when the matching provider is absent from the scan.

  $ mkdir -p ../digests
  $ cd "$ROOT/digests"
  $ cat > left.ml <<'EOF'
  > exception Used = Not_found
  > EOF
  $ ocamlc -w -a -bin-annot -c "$PWD/left.ml"
  $ cat > right.ml <<'EOF'
  > exception Used = Not_found
  > EOF
  $ ocamlc -w -a -bin-annot -c "$PWD/right.ml"
  $ mkdir -p one
  $ cd "$ROOT/digests/one"
  $ cat > target.ml <<'EOF'
  > module Inner = Left
  > EOF
  $ ocamlc -w -a -bin-annot -I "$ROOT/digests" -c "$PWD/target.ml"
  $ mkdir -p ../two
  $ cd "$ROOT/digests/two"
  $ cat > target.ml <<'EOF'
  > module Inner = Right
  > EOF
  $ ocamlc -w -a -bin-annot -I "$ROOT/digests" -c "$PWD/target.ml"
  $ cd "$ROOT/digests/one"
  $ cat > foo.ml <<'EOF'
  > module Alias = Target.Inner
  > EOF
  $ ocamlc -w -a -bin-annot -I "$ROOT/digests" -c "$PWD/foo.ml"
  $ cd "$ROOT/digests/two"
  $ cat > foo.ml <<'EOF'
  > module Alias = Right
  > EOF
  $ ocamlc -w -a -bin-annot -I "$ROOT/digests" -c "$PWD/foo.ml"
  $ mkdir -p ../consumer
  $ cd "$ROOT/digests/consumer"
  $ cat > use.ml <<'EOF'
  > let () = raise Foo.Alias.Used
  > EOF
  $ ocamlc -w -a -bin-annot -I "$ROOT/digests/one" -I "$ROOT/digests" -c "$PWD/use.ml"

Layout forward.

  $ cd "$ROOT/digests"
  $ mkdir -p forward/consumer
  $ cp left.cmt forward/consumer
  $ cp right.cmt forward/consumer
  $ cp consumer/use.cmt forward/consumer
  $ mkdir -p forward/a
  $ cp one/foo.cmt forward/a
  $ mkdir -p forward/z
  $ cp two/foo.cmt forward/z
  $ mkdir -p forward/y
  $ cp one/target.cmt forward/y
  $ mkdir -p forward/b
  $ cp two/target.cmt forward/b
  $ reanalyze.exe -ci -debug -native-build-target . -dce-cmt "$ROOT/digests/forward" > forward.out 2>/dev/null
  $ grep -m1 -oF -- 'Live Exception +left.Used:' forward.out
  Live Exception +left.Used:
  $ grep -m1 -oF -- 'Dead Exception +left.Used:' forward.out
  [1]
  $ grep -m1 -oF -- 'Dead Exception +right.Used:' forward.out
  Dead Exception +right.Used:
  $ grep -m1 -oF -- 'Live Exception +right.Used:' forward.out
  [1]

Layout reverse.

  $ mkdir -p reverse/consumer
  $ cp left.cmt reverse/consumer
  $ cp right.cmt reverse/consumer
  $ cp consumer/use.cmt reverse/consumer
  $ mkdir -p reverse/z
  $ cp one/foo.cmt reverse/z
  $ mkdir -p reverse/a
  $ cp two/foo.cmt reverse/a
  $ mkdir -p reverse/b
  $ cp one/target.cmt reverse/b
  $ mkdir -p reverse/y
  $ cp two/target.cmt reverse/y
  $ reanalyze.exe -ci -debug -native-build-target . -dce-cmt "$ROOT/digests/reverse" > reverse.out 2>/dev/null
  $ grep -m1 -oF -- 'Live Exception +left.Used:' reverse.out
  Live Exception +left.Used:
  $ grep -m1 -oF -- 'Dead Exception +left.Used:' reverse.out
  [1]
  $ grep -m1 -oF -- 'Dead Exception +right.Used:' reverse.out
  Dead Exception +right.Used:
  $ grep -m1 -oF -- 'Live Exception +right.Used:' reverse.out
  [1]

Layout missing-foo.

  $ mkdir -p missing-foo/consumer
  $ cp left.cmt missing-foo/consumer
  $ cp right.cmt missing-foo/consumer
  $ cp consumer/use.cmt missing-foo/consumer
  $ mkdir -p missing-foo/z
  $ cp two/foo.cmt missing-foo/z
  $ mkdir -p missing-foo/y
  $ cp one/target.cmt missing-foo/y
  $ mkdir -p missing-foo/b
  $ cp two/target.cmt missing-foo/b
  $ reanalyze.exe -ci -debug -native-build-target . -dce-cmt "$ROOT/digests/missing-foo" > missing-foo.out 2>/dev/null
  $ grep -m1 -oF -- 'Dead Exception +left.Used:' missing-foo.out
  Dead Exception +left.Used:
  $ grep -m1 -oF -- 'Live Exception +left.Used:' missing-foo.out
  [1]
  $ grep -m1 -oF -- 'Dead Exception +right.Used:' missing-foo.out
  Dead Exception +right.Used:
  $ grep -m1 -oF -- 'Live Exception +right.Used:' missing-foo.out
  [1]

Layout missing-target.

  $ mkdir -p missing-target/consumer
  $ cp left.cmt missing-target/consumer
  $ cp right.cmt missing-target/consumer
  $ cp consumer/use.cmt missing-target/consumer
  $ mkdir -p missing-target/a
  $ cp one/foo.cmt missing-target/a
  $ mkdir -p missing-target/z
  $ cp two/foo.cmt missing-target/z
  $ mkdir -p missing-target/b
  $ cp two/target.cmt missing-target/b
  $ reanalyze.exe -ci -debug -native-build-target . -dce-cmt "$ROOT/digests/missing-target" > missing-target.out 2>/dev/null
  $ grep -m1 -oF -- 'Dead Exception +left.Used:' missing-target.out
  Dead Exception +left.Used:
  $ grep -m1 -oF -- 'Live Exception +left.Used:' missing-target.out
  [1]
  $ grep -m1 -oF -- 'Dead Exception +right.Used:' missing-target.out
  Dead Exception +right.Used:
  $ grep -m1 -oF -- 'Live Exception +right.Used:' missing-target.out
  [1]
