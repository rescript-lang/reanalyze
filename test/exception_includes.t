Exceptions exported through includes: Wrapper includes or rebinds the
exceptions of Source (or Other), and use.ml raises them through Wrapper.
Each case lives in its own directory includes/NAME.

  $ ROOT=$PWD

Case direct.

  $ mkdir -p includes/direct
  $ cd "$ROOT/includes/direct"
  $ cat > source.ml <<'EOF'
  > exception Used = Not_found
  > exception Unused = Not_found
  > EOF
  $ ocamlc -w -a -bin-annot -c "$PWD/source.ml"
  $ cat > other.ml <<'EOF'
  > exception Used = Not_found
  > exception Unused = Not_found
  > EOF
  $ ocamlc -w -a -bin-annot -c "$PWD/other.ml"
  $ cat > relay.ml <<'EOF'
  > include Source
  > EOF
  $ ocamlc -w -a -bin-annot -c "$PWD/relay.ml"
  $ cat > wrapper.ml <<'EOF'
  > include Source
  > EOF
  $ ocamlc -w -a -bin-annot -c "$PWD/wrapper.ml"
  $ cat > use.ml <<'EOF'
  > let () = raise Wrapper.Used
  > EOF
  $ ocamlc -w -a -bin-annot -c "$PWD/use.ml"
  $ reanalyze.exe -ci -debug -native-build-target . -dce-cmt . > analysis.out 2>/dev/null
  $ grep -m1 -oF -- 'Live Exception +source.Used:' analysis.out
  Live Exception +source.Used:
  $ grep -m1 -oF -- 'Dead Exception +source.Used:' analysis.out
  [1]
  $ grep -m1 -oF -- 'Dead Exception +other.Used:' analysis.out
  Dead Exception +other.Used:
  $ grep -m1 -oF -- 'Live Exception +other.Used:' analysis.out
  [1]
  $ grep -m1 -oF -- 'Dead Exception +source.Unused:' analysis.out
  Dead Exception +source.Unused:
  $ grep -m1 -oF -- 'Live Exception +source.Unused:' analysis.out
  [1]
  $ grep -m1 -oF -- 'Dead Exception +other.Unused:' analysis.out
  Dead Exception +other.Unused:
  $ grep -m1 -oF -- 'Live Exception +other.Unused:' analysis.out
  [1]

Case chained.

  $ mkdir -p ../chained
  $ cd "$ROOT/includes/chained"
  $ cat > source.ml <<'EOF'
  > exception Used = Not_found
  > exception Unused = Not_found
  > EOF
  $ ocamlc -w -a -bin-annot -c "$PWD/source.ml"
  $ cat > other.ml <<'EOF'
  > exception Used = Not_found
  > exception Unused = Not_found
  > EOF
  $ ocamlc -w -a -bin-annot -c "$PWD/other.ml"
  $ cat > relay.ml <<'EOF'
  > include Source
  > EOF
  $ ocamlc -w -a -bin-annot -c "$PWD/relay.ml"
  $ cat > wrapper.ml <<'EOF'
  > include Relay
  > EOF
  $ ocamlc -w -a -bin-annot -c "$PWD/wrapper.ml"
  $ cat > use.ml <<'EOF'
  > let () = raise Wrapper.Used
  > EOF
  $ ocamlc -w -a -bin-annot -c "$PWD/use.ml"
  $ reanalyze.exe -ci -debug -native-build-target . -dce-cmt . > analysis.out 2>/dev/null
  $ grep -m1 -oF -- 'Live Exception +source.Used:' analysis.out
  Live Exception +source.Used:
  $ grep -m1 -oF -- 'Dead Exception +source.Used:' analysis.out
  [1]
  $ grep -m1 -oF -- 'Dead Exception +other.Used:' analysis.out
  Dead Exception +other.Used:
  $ grep -m1 -oF -- 'Live Exception +other.Used:' analysis.out
  [1]
  $ grep -m1 -oF -- 'Dead Exception +source.Unused:' analysis.out
  Dead Exception +source.Unused:
  $ grep -m1 -oF -- 'Live Exception +source.Unused:' analysis.out
  [1]
  $ grep -m1 -oF -- 'Dead Exception +other.Unused:' analysis.out
  Dead Exception +other.Unused:
  $ grep -m1 -oF -- 'Live Exception +other.Unused:' analysis.out
  [1]

Case constrained.

  $ mkdir -p ../constrained
  $ cd "$ROOT/includes/constrained"
  $ cat > source.ml <<'EOF'
  > exception Used = Not_found
  > exception Unused = Not_found
  > EOF
  $ ocamlc -w -a -bin-annot -c "$PWD/source.ml"
  $ cat > other.ml <<'EOF'
  > exception Used = Not_found
  > exception Unused = Not_found
  > EOF
  $ ocamlc -w -a -bin-annot -c "$PWD/other.ml"
  $ cat > relay.ml <<'EOF'
  > include Source
  > EOF
  $ ocamlc -w -a -bin-annot -c "$PWD/relay.ml"
  $ cat > wrapper.ml <<'EOF'
  > include (Source : sig exception Used exception Unused end)
  > EOF
  $ ocamlc -w -a -bin-annot -c "$PWD/wrapper.ml"
  $ cat > use.ml <<'EOF'
  > let () = raise Wrapper.Used
  > EOF
  $ ocamlc -w -a -bin-annot -c "$PWD/use.ml"
  $ reanalyze.exe -ci -debug -native-build-target . -dce-cmt . > analysis.out 2>/dev/null
  $ grep -m1 -oF -- 'Live Exception +source.Used:' analysis.out
  Live Exception +source.Used:
  $ grep -m1 -oF -- 'Dead Exception +source.Used:' analysis.out
  [1]
  $ grep -m1 -oF -- 'Dead Exception +other.Used:' analysis.out
  Dead Exception +other.Used:
  $ grep -m1 -oF -- 'Live Exception +other.Used:' analysis.out
  [1]
  $ grep -m1 -oF -- 'Dead Exception +source.Unused:' analysis.out
  Dead Exception +source.Unused:
  $ grep -m1 -oF -- 'Live Exception +source.Unused:' analysis.out
  [1]
  $ grep -m1 -oF -- 'Dead Exception +other.Unused:' analysis.out
  Dead Exception +other.Unused:
  $ grep -m1 -oF -- 'Live Exception +other.Unused:' analysis.out
  [1]

Case named-constraint.

  $ mkdir -p ../named-constraint
  $ cd "$ROOT/includes/named-constraint"
  $ cat > source.ml <<'EOF'
  > exception Used = Not_found
  > exception Unused = Not_found
  > EOF
  $ ocamlc -w -a -bin-annot -c "$PWD/source.ml"
  $ cat > other.ml <<'EOF'
  > exception Used = Not_found
  > exception Unused = Not_found
  > EOF
  $ ocamlc -w -a -bin-annot -c "$PWD/other.ml"
  $ cat > relay.ml <<'EOF'
  > include Source
  > EOF
  $ ocamlc -w -a -bin-annot -c "$PWD/relay.ml"
  $ cat > wrapper.ml <<'EOF'
  > module type S = sig exception Used exception Unused end
  > include (Source : S)
  > EOF
  $ ocamlc -w -a -bin-annot -c "$PWD/wrapper.ml"
  $ cat > use.ml <<'EOF'
  > let () = raise Wrapper.Used
  > EOF
  $ ocamlc -w -a -bin-annot -c "$PWD/use.ml"
  $ reanalyze.exe -ci -debug -native-build-target . -dce-cmt . > analysis.out 2>/dev/null
  $ grep -m1 -oF -- 'Live Exception +source.Used:' analysis.out
  Live Exception +source.Used:
  $ grep -m1 -oF -- 'Dead Exception +source.Used:' analysis.out
  [1]
  $ grep -m1 -oF -- 'Dead Exception +other.Used:' analysis.out
  Dead Exception +other.Used:
  $ grep -m1 -oF -- 'Live Exception +other.Used:' analysis.out
  [1]
  $ grep -m1 -oF -- 'Dead Exception +source.Unused:' analysis.out
  Dead Exception +source.Unused:
  $ grep -m1 -oF -- 'Live Exception +source.Unused:' analysis.out
  [1]
  $ grep -m1 -oF -- 'Dead Exception +other.Unused:' analysis.out
  Dead Exception +other.Unused:
  $ grep -m1 -oF -- 'Live Exception +other.Unused:' analysis.out
  [1]

Case nested.

  $ mkdir -p ../nested
  $ cd "$ROOT/includes/nested"
  $ cat > source.ml <<'EOF'
  > exception Used = Not_found
  > exception Unused = Not_found
  > EOF
  $ ocamlc -w -a -bin-annot -c "$PWD/source.ml"
  $ cat > other.ml <<'EOF'
  > exception Used = Not_found
  > exception Unused = Not_found
  > EOF
  $ ocamlc -w -a -bin-annot -c "$PWD/other.ml"
  $ cat > relay.ml <<'EOF'
  > include Source
  > EOF
  $ ocamlc -w -a -bin-annot -c "$PWD/relay.ml"
  $ cat > wrapper.ml <<'EOF'
  > module Nested = struct include Source end
  > EOF
  $ ocamlc -w -a -bin-annot -c "$PWD/wrapper.ml"
  $ cat > use.ml <<'EOF'
  > let () = raise Wrapper.Nested.Used
  > EOF
  $ ocamlc -w -a -bin-annot -c "$PWD/use.ml"
  $ reanalyze.exe -ci -debug -native-build-target . -dce-cmt . > analysis.out 2>/dev/null
  $ grep -m1 -oF -- 'Live Exception +source.Used:' analysis.out
  Live Exception +source.Used:
  $ grep -m1 -oF -- 'Dead Exception +source.Used:' analysis.out
  [1]
  $ grep -m1 -oF -- 'Dead Exception +other.Used:' analysis.out
  Dead Exception +other.Used:
  $ grep -m1 -oF -- 'Live Exception +other.Used:' analysis.out
  [1]
  $ grep -m1 -oF -- 'Dead Exception +source.Unused:' analysis.out
  Dead Exception +source.Unused:
  $ grep -m1 -oF -- 'Live Exception +source.Unused:' analysis.out
  [1]
  $ grep -m1 -oF -- 'Dead Exception +other.Unused:' analysis.out
  Dead Exception +other.Unused:
  $ grep -m1 -oF -- 'Live Exception +other.Unused:' analysis.out
  [1]

Case nested-constraint.

  $ mkdir -p ../nested-constraint
  $ cd "$ROOT/includes/nested-constraint"
  $ cat > source.ml <<'EOF'
  > exception Used = Not_found
  > exception Unused = Not_found
  > EOF
  $ ocamlc -w -a -bin-annot -c "$PWD/source.ml"
  $ cat > other.ml <<'EOF'
  > exception Used = Not_found
  > exception Unused = Not_found
  > EOF
  $ ocamlc -w -a -bin-annot -c "$PWD/other.ml"
  $ cat > relay.ml <<'EOF'
  > include Source
  > EOF
  $ ocamlc -w -a -bin-annot -c "$PWD/relay.ml"
  $ cat > wrapper.ml <<'EOF'
  > include (struct module Nested = Source end : sig module Nested : sig exception Used exception Unused end end)
  > EOF
  $ ocamlc -w -a -bin-annot -c "$PWD/wrapper.ml"
  $ cat > use.ml <<'EOF'
  > let () = raise Wrapper.Nested.Used
  > EOF
  $ ocamlc -w -a -bin-annot -c "$PWD/use.ml"
  $ reanalyze.exe -ci -debug -native-build-target . -dce-cmt . > analysis.out 2>/dev/null
  $ grep -m1 -oF -- 'Live Exception +source.Used:' analysis.out
  Live Exception +source.Used:
  $ grep -m1 -oF -- 'Dead Exception +source.Used:' analysis.out
  [1]
  $ grep -m1 -oF -- 'Dead Exception +other.Used:' analysis.out
  Dead Exception +other.Used:
  $ grep -m1 -oF -- 'Live Exception +other.Used:' analysis.out
  [1]
  $ grep -m1 -oF -- 'Dead Exception +source.Unused:' analysis.out
  Dead Exception +source.Unused:
  $ grep -m1 -oF -- 'Live Exception +source.Unused:' analysis.out
  [1]
  $ grep -m1 -oF -- 'Dead Exception +other.Unused:' analysis.out
  Dead Exception +other.Unused:
  $ grep -m1 -oF -- 'Live Exception +other.Unused:' analysis.out
  [1]

Case local.

  $ mkdir -p ../local
  $ cd "$ROOT/includes/local"
  $ cat > source.ml <<'EOF'
  > exception Used = Not_found
  > exception Unused = Not_found
  > EOF
  $ ocamlc -w -a -bin-annot -c "$PWD/source.ml"
  $ cat > other.ml <<'EOF'
  > exception Used = Not_found
  > exception Unused = Not_found
  > EOF
  $ ocamlc -w -a -bin-annot -c "$PWD/other.ml"
  $ cat > relay.ml <<'EOF'
  > include Source
  > EOF
  $ ocamlc -w -a -bin-annot -c "$PWD/relay.ml"
  $ cat > wrapper.ml <<'EOF'
  > module Local = struct exception Used = Not_found
  > exception Unused = Not_found
  > end
  > include Local
  > EOF
  $ ocamlc -w -a -bin-annot -c "$PWD/wrapper.ml"
  $ cat > use.ml <<'EOF'
  > let () = raise Wrapper.Used
  > EOF
  $ ocamlc -w -a -bin-annot -c "$PWD/use.ml"
  $ reanalyze.exe -ci -debug -native-build-target . -dce-cmt . > analysis.out 2>/dev/null
  $ grep -m1 -oF -- 'Live Exception +wrapper.Local.Used:' analysis.out
  Live Exception +wrapper.Local.Used:
  $ grep -m1 -oF -- 'Dead Exception +wrapper.Local.Used:' analysis.out
  [1]
  $ grep -m1 -oF -- 'Dead Exception +source.Used:' analysis.out
  Dead Exception +source.Used:
  $ grep -m1 -oF -- 'Live Exception +source.Used:' analysis.out
  [1]
  $ grep -m1 -oF -- 'Dead Exception +other.Used:' analysis.out
  Dead Exception +other.Used:
  $ grep -m1 -oF -- 'Live Exception +other.Used:' analysis.out
  [1]
  $ grep -m1 -oF -- 'Dead Exception +wrapper.Local.Unused:' analysis.out
  Dead Exception +wrapper.Local.Unused:
  $ grep -m1 -oF -- 'Live Exception +wrapper.Local.Unused:' analysis.out
  [1]
  $ grep -m1 -oF -- 'Dead Exception +source.Unused:' analysis.out
  Dead Exception +source.Unused:
  $ grep -m1 -oF -- 'Live Exception +source.Unused:' analysis.out
  [1]
  $ grep -m1 -oF -- 'Dead Exception +other.Unused:' analysis.out
  Dead Exception +other.Unused:
  $ grep -m1 -oF -- 'Live Exception +other.Unused:' analysis.out
  [1]

Case anonymous.

  $ mkdir -p ../anonymous
  $ cd "$ROOT/includes/anonymous"
  $ cat > source.ml <<'EOF'
  > exception Used = Not_found
  > exception Unused = Not_found
  > EOF
  $ ocamlc -w -a -bin-annot -c "$PWD/source.ml"
  $ cat > other.ml <<'EOF'
  > exception Used = Not_found
  > exception Unused = Not_found
  > EOF
  $ ocamlc -w -a -bin-annot -c "$PWD/other.ml"
  $ cat > relay.ml <<'EOF'
  > include Source
  > EOF
  $ ocamlc -w -a -bin-annot -c "$PWD/relay.ml"
  $ cat > wrapper.ml <<'EOF'
  > include struct exception Used = Not_found
  > exception Unused = Not_found
  > end
  > EOF
  $ ocamlc -w -a -bin-annot -c "$PWD/wrapper.ml"
  $ cat > use.ml <<'EOF'
  > let () = raise Wrapper.Used
  > EOF
  $ ocamlc -w -a -bin-annot -c "$PWD/use.ml"
  $ reanalyze.exe -ci -debug -native-build-target . -dce-cmt . > analysis.out 2>/dev/null
  $ grep -m1 -oF -- 'Live Exception +wrapper.Used:' analysis.out
  Live Exception +wrapper.Used:
  $ grep -m1 -oF -- 'Dead Exception +wrapper.Used:' analysis.out
  [1]
  $ grep -m1 -oF -- 'Dead Exception +source.Used:' analysis.out
  Dead Exception +source.Used:
  $ grep -m1 -oF -- 'Live Exception +source.Used:' analysis.out
  [1]
  $ grep -m1 -oF -- 'Dead Exception +other.Used:' analysis.out
  Dead Exception +other.Used:
  $ grep -m1 -oF -- 'Live Exception +other.Used:' analysis.out
  [1]
  $ grep -m1 -oF -- 'Dead Exception +wrapper.Unused:' analysis.out
  Dead Exception +wrapper.Unused:
  $ grep -m1 -oF -- 'Live Exception +wrapper.Unused:' analysis.out
  [1]
  $ grep -m1 -oF -- 'Dead Exception +source.Unused:' analysis.out
  Dead Exception +source.Unused:
  $ grep -m1 -oF -- 'Live Exception +source.Unused:' analysis.out
  [1]
  $ grep -m1 -oF -- 'Dead Exception +other.Unused:' analysis.out
  Dead Exception +other.Unused:
  $ grep -m1 -oF -- 'Live Exception +other.Unused:' analysis.out
  [1]

Case anonymous-nested.

  $ mkdir -p ../anonymous-nested
  $ cd "$ROOT/includes/anonymous-nested"
  $ cat > source.ml <<'EOF'
  > exception Used = Not_found
  > exception Unused = Not_found
  > EOF
  $ ocamlc -w -a -bin-annot -c "$PWD/source.ml"
  $ cat > other.ml <<'EOF'
  > exception Used = Not_found
  > exception Unused = Not_found
  > EOF
  $ ocamlc -w -a -bin-annot -c "$PWD/other.ml"
  $ cat > relay.ml <<'EOF'
  > include Source
  > EOF
  $ ocamlc -w -a -bin-annot -c "$PWD/relay.ml"
  $ cat > wrapper.ml <<'EOF'
  > include struct include Source end
  > EOF
  $ ocamlc -w -a -bin-annot -c "$PWD/wrapper.ml"
  $ cat > use.ml <<'EOF'
  > let () = raise Wrapper.Used
  > EOF
  $ ocamlc -w -a -bin-annot -c "$PWD/use.ml"
  $ reanalyze.exe -ci -debug -native-build-target . -dce-cmt . > analysis.out 2>/dev/null
  $ grep -m1 -oF -- 'Live Exception +source.Used:' analysis.out
  Live Exception +source.Used:
  $ grep -m1 -oF -- 'Dead Exception +source.Used:' analysis.out
  [1]
  $ grep -m1 -oF -- 'Dead Exception +other.Used:' analysis.out
  Dead Exception +other.Used:
  $ grep -m1 -oF -- 'Live Exception +other.Used:' analysis.out
  [1]
  $ grep -m1 -oF -- 'Dead Exception +source.Unused:' analysis.out
  Dead Exception +source.Unused:
  $ grep -m1 -oF -- 'Live Exception +source.Unused:' analysis.out
  [1]
  $ grep -m1 -oF -- 'Dead Exception +other.Unused:' analysis.out
  Dead Exception +other.Unused:
  $ grep -m1 -oF -- 'Live Exception +other.Unused:' analysis.out
  [1]

Case local-alias.

  $ mkdir -p ../local-alias
  $ cd "$ROOT/includes/local-alias"
  $ cat > source.ml <<'EOF'
  > exception Used = Not_found
  > exception Unused = Not_found
  > EOF
  $ ocamlc -w -a -bin-annot -c "$PWD/source.ml"
  $ cat > other.ml <<'EOF'
  > exception Used = Not_found
  > exception Unused = Not_found
  > EOF
  $ ocamlc -w -a -bin-annot -c "$PWD/other.ml"
  $ cat > relay.ml <<'EOF'
  > include Source
  > EOF
  $ ocamlc -w -a -bin-annot -c "$PWD/relay.ml"
  $ cat > wrapper.ml <<'EOF'
  > module Alias = Source
  > include Alias
  > EOF
  $ ocamlc -w -a -bin-annot -c "$PWD/wrapper.ml"
  $ cat > use.ml <<'EOF'
  > let () = raise Wrapper.Used
  > EOF
  $ ocamlc -w -a -bin-annot -c "$PWD/use.ml"
  $ reanalyze.exe -ci -debug -native-build-target . -dce-cmt . > analysis.out 2>/dev/null
  $ grep -m1 -oF -- 'Live Exception +source.Used:' analysis.out
  Live Exception +source.Used:
  $ grep -m1 -oF -- 'Dead Exception +source.Used:' analysis.out
  [1]
  $ grep -m1 -oF -- 'Dead Exception +other.Used:' analysis.out
  Dead Exception +other.Used:
  $ grep -m1 -oF -- 'Live Exception +other.Used:' analysis.out
  [1]
  $ grep -m1 -oF -- 'Dead Exception +source.Unused:' analysis.out
  Dead Exception +source.Unused:
  $ grep -m1 -oF -- 'Live Exception +source.Unused:' analysis.out
  [1]
  $ grep -m1 -oF -- 'Dead Exception +other.Unused:' analysis.out
  Dead Exception +other.Unused:
  $ grep -m1 -oF -- 'Live Exception +other.Unused:' analysis.out
  [1]

Case captured-alias.

  $ mkdir -p ../captured-alias
  $ cd "$ROOT/includes/captured-alias"
  $ cat > source.ml <<'EOF'
  > exception Used = Not_found
  > exception Unused = Not_found
  > EOF
  $ ocamlc -w -a -bin-annot -c "$PWD/source.ml"
  $ cat > other.ml <<'EOF'
  > exception Used = Not_found
  > exception Unused = Not_found
  > EOF
  $ ocamlc -w -a -bin-annot -c "$PWD/other.ml"
  $ cat > relay.ml <<'EOF'
  > include Source
  > EOF
  $ ocamlc -w -a -bin-annot -c "$PWD/relay.ml"
  $ cat > wrapper.ml <<'EOF'
  > include struct module Target = Source end
  > module Saved = Target
  > module Target = Other
  > include Saved
  > EOF
  $ ocamlc -w -a -bin-annot -c "$PWD/wrapper.ml"
  $ cat > use.ml <<'EOF'
  > let () = raise Wrapper.Used
  > EOF
  $ ocamlc -w -a -bin-annot -c "$PWD/use.ml"
  $ reanalyze.exe -ci -debug -native-build-target . -dce-cmt . > analysis.out 2>/dev/null
  $ grep -m1 -oF -- 'Live Exception +source.Used:' analysis.out
  Live Exception +source.Used:
  $ grep -m1 -oF -- 'Dead Exception +source.Used:' analysis.out
  [1]
  $ grep -m1 -oF -- 'Dead Exception +other.Used:' analysis.out
  Dead Exception +other.Used:
  $ grep -m1 -oF -- 'Live Exception +other.Used:' analysis.out
  [1]
  $ grep -m1 -oF -- 'Dead Exception +source.Unused:' analysis.out
  Dead Exception +source.Unused:
  $ grep -m1 -oF -- 'Live Exception +source.Unused:' analysis.out
  [1]
  $ grep -m1 -oF -- 'Dead Exception +other.Unused:' analysis.out
  Dead Exception +other.Unused:
  $ grep -m1 -oF -- 'Live Exception +other.Unused:' analysis.out
  [1]

Case captured-module.

  $ mkdir -p ../captured-module
  $ cd "$ROOT/includes/captured-module"
  $ cat > source.ml <<'EOF'
  > exception Used = Not_found
  > exception Unused = Not_found
  > EOF
  $ ocamlc -w -a -bin-annot -c "$PWD/source.ml"
  $ cat > other.ml <<'EOF'
  > exception Used = Not_found
  > exception Unused = Not_found
  > EOF
  $ ocamlc -w -a -bin-annot -c "$PWD/other.ml"
  $ cat > relay.ml <<'EOF'
  > include Source
  > EOF
  $ ocamlc -w -a -bin-annot -c "$PWD/relay.ml"
  $ cat > wrapper.ml <<'EOF'
  > include struct module M = struct include Source end end
  > module Saved = M
  > module M = struct include Other end
  > EOF
  $ ocamlc -w -a -bin-annot -c "$PWD/wrapper.ml"
  $ cat > use.ml <<'EOF'
  > let () = raise Wrapper.Saved.Used
  > EOF
  $ ocamlc -w -a -bin-annot -c "$PWD/use.ml"
  $ reanalyze.exe -ci -debug -native-build-target . -dce-cmt . > analysis.out 2>/dev/null
  $ grep -m1 -oF -- 'Live Exception +source.Used:' analysis.out
  Live Exception +source.Used:
  $ grep -m1 -oF -- 'Dead Exception +source.Used:' analysis.out
  [1]
  $ grep -m1 -oF -- 'Dead Exception +other.Used:' analysis.out
  Dead Exception +other.Used:
  $ grep -m1 -oF -- 'Live Exception +other.Used:' analysis.out
  [1]
  $ grep -m1 -oF -- 'Dead Exception +source.Unused:' analysis.out
  Dead Exception +source.Unused:
  $ grep -m1 -oF -- 'Live Exception +source.Unused:' analysis.out
  [1]
  $ grep -m1 -oF -- 'Dead Exception +other.Unused:' analysis.out
  Dead Exception +other.Unused:
  $ grep -m1 -oF -- 'Live Exception +other.Unused:' analysis.out
  [1]

Case last-include.

  $ mkdir -p ../last-include
  $ cd "$ROOT/includes/last-include"
  $ cat > source.ml <<'EOF'
  > exception Used = Not_found
  > exception Unused = Not_found
  > EOF
  $ ocamlc -w -a -bin-annot -c "$PWD/source.ml"
  $ cat > other.ml <<'EOF'
  > exception Used = Not_found
  > exception Unused = Not_found
  > EOF
  $ ocamlc -w -a -bin-annot -c "$PWD/other.ml"
  $ cat > relay.ml <<'EOF'
  > include Source
  > EOF
  $ ocamlc -w -a -bin-annot -c "$PWD/relay.ml"
  $ cat > wrapper.ml <<'EOF'
  > include Source
  > include Other
  > EOF
  $ ocamlc -w -a -bin-annot -c "$PWD/wrapper.ml"
  $ cat > use.ml <<'EOF'
  > let () = raise Wrapper.Used
  > EOF
  $ ocamlc -w -a -bin-annot -c "$PWD/use.ml"
  $ reanalyze.exe -ci -debug -native-build-target . -dce-cmt . > analysis.out 2>/dev/null
  $ grep -m1 -oF -- 'Live Exception +other.Used:' analysis.out
  Live Exception +other.Used:
  $ grep -m1 -oF -- 'Dead Exception +other.Used:' analysis.out
  [1]
  $ grep -m1 -oF -- 'Dead Exception +source.Used:' analysis.out
  Dead Exception +source.Used:
  $ grep -m1 -oF -- 'Live Exception +source.Used:' analysis.out
  [1]
  $ grep -m1 -oF -- 'Dead Exception +source.Unused:' analysis.out
  Dead Exception +source.Unused:
  $ grep -m1 -oF -- 'Live Exception +source.Unused:' analysis.out
  [1]
  $ grep -m1 -oF -- 'Dead Exception +other.Unused:' analysis.out
  Dead Exception +other.Unused:
  $ grep -m1 -oF -- 'Live Exception +other.Unused:' analysis.out
  [1]

Case rebound.

  $ mkdir -p ../rebound
  $ cd "$ROOT/includes/rebound"
  $ cat > source.ml <<'EOF'
  > exception Used = Not_found
  > exception Unused = Not_found
  > EOF
  $ ocamlc -w -a -bin-annot -c "$PWD/source.ml"
  $ cat > other.ml <<'EOF'
  > exception Used = Not_found
  > exception Unused = Not_found
  > EOF
  $ ocamlc -w -a -bin-annot -c "$PWD/other.ml"
  $ cat > relay.ml <<'EOF'
  > include Source
  > EOF
  $ ocamlc -w -a -bin-annot -c "$PWD/relay.ml"
  $ cat > wrapper.ml <<'EOF'
  > include Source
  > exception Used = Other.Used
  > EOF
  $ ocamlc -w -a -bin-annot -c "$PWD/wrapper.ml"
  $ cat > use.ml <<'EOF'
  > let () = raise Wrapper.Used
  > EOF
  $ ocamlc -w -a -bin-annot -c "$PWD/use.ml"
  $ reanalyze.exe -ci -debug -native-build-target . -dce-cmt . > analysis.out 2>/dev/null
  $ grep -m1 -oF -- 'Live Exception +wrapper.Used:' analysis.out
  Live Exception +wrapper.Used:
  $ grep -m1 -oF -- 'Dead Exception +wrapper.Used:' analysis.out
  [1]
  $ grep -m1 -oF -- 'Dead Exception +source.Used:' analysis.out
  Dead Exception +source.Used:
  $ grep -m1 -oF -- 'Live Exception +source.Used:' analysis.out
  [1]
  $ grep -m1 -oF -- 'Dead Exception +source.Unused:' analysis.out
  Dead Exception +source.Unused:
  $ grep -m1 -oF -- 'Live Exception +source.Unused:' analysis.out
  [1]
  $ grep -m1 -oF -- 'Dead Exception +other.Unused:' analysis.out
  Dead Exception +other.Unused:
  $ grep -m1 -oF -- 'Live Exception +other.Unused:' analysis.out
  [1]

Case let-local.

  $ mkdir -p ../let-local
  $ cd "$ROOT/includes/let-local"
  $ cat > source.ml <<'EOF'
  > exception Used = Not_found
  > exception Unused = Not_found
  > EOF
  $ ocamlc -w -a -bin-annot -c "$PWD/source.ml"
  $ cat > other.ml <<'EOF'
  > exception Used = Not_found
  > exception Unused = Not_found
  > EOF
  $ ocamlc -w -a -bin-annot -c "$PWD/other.ml"
  $ cat > relay.ml <<'EOF'
  > include Source
  > EOF
  $ ocamlc -w -a -bin-annot -c "$PWD/relay.ml"
  $ cat > wrapper.ml <<'EOF'
  > include Source
  > EOF
  $ ocamlc -w -a -bin-annot -c "$PWD/wrapper.ml"
  $ cat > use.ml <<'EOF'
  > let () = raise (let module Local = struct include Wrapper end in Local.Used)
  > EOF
  $ ocamlc -w -a -bin-annot -c "$PWD/use.ml"
  $ reanalyze.exe -ci -debug -native-build-target . -dce-cmt . > analysis.out 2>/dev/null
  $ grep -m1 -oF -- 'Live Exception +source.Used:' analysis.out
  Live Exception +source.Used:
  $ grep -m1 -oF -- 'Dead Exception +source.Used:' analysis.out
  [1]
  $ grep -m1 -oF -- 'Dead Exception +other.Used:' analysis.out
  Dead Exception +other.Used:
  $ grep -m1 -oF -- 'Live Exception +other.Used:' analysis.out
  [1]
  $ grep -m1 -oF -- 'Dead Exception +source.Unused:' analysis.out
  Dead Exception +source.Unused:
  $ grep -m1 -oF -- 'Live Exception +source.Unused:' analysis.out
  [1]
  $ grep -m1 -oF -- 'Dead Exception +other.Unused:' analysis.out
  Dead Exception +other.Unused:
  $ grep -m1 -oF -- 'Live Exception +other.Unused:' analysis.out
  [1]

Case captured-exception.

  $ mkdir -p ../captured-exception
  $ cd "$ROOT/includes/captured-exception"
  $ cat > source.ml <<'EOF'
  > exception Used = Not_found
  > exception Unused = Not_found
  > EOF
  $ ocamlc -w -a -bin-annot -c "$PWD/source.ml"
  $ cat > other.ml <<'EOF'
  > exception Used = Not_found
  > exception Unused = Not_found
  > EOF
  $ ocamlc -w -a -bin-annot -c "$PWD/other.ml"
  $ cat > relay.ml <<'EOF'
  > include Source
  > EOF
  $ ocamlc -w -a -bin-annot -c "$PWD/relay.ml"
  $ cat > wrapper.ml <<'EOF'
  > include Source
  > let saved () = raise Used
  > include Other
  > EOF
  $ ocamlc -w -a -bin-annot -c "$PWD/wrapper.ml"
  $ cat > use.ml <<'EOF'
  > let () = raise (Wrapper.saved (); Wrapper.Used)
  > EOF
  $ ocamlc -w -a -bin-annot -c "$PWD/use.ml"
  $ reanalyze.exe -ci -debug -native-build-target . -dce-cmt . > analysis.out 2>/dev/null
  $ grep -m1 -oF -- 'Live Exception +source.Used:' analysis.out
  Live Exception +source.Used:
  $ grep -m1 -oF -- 'Dead Exception +source.Used:' analysis.out
  [1]
  $ grep -m1 -oF -- 'Live Exception +other.Used:' analysis.out
  Live Exception +other.Used:
  $ grep -m1 -oF -- 'Dead Exception +other.Used:' analysis.out
  [1]
  $ grep -m1 -oF -- 'Dead Exception +source.Unused:' analysis.out
  Dead Exception +source.Unused:
  $ grep -m1 -oF -- 'Live Exception +source.Unused:' analysis.out
  [1]
  $ grep -m1 -oF -- 'Dead Exception +other.Unused:' analysis.out
  Dead Exception +other.Unused:
  $ grep -m1 -oF -- 'Live Exception +other.Unused:' analysis.out
  [1]

Case captured-before-rebind.

  $ mkdir -p ../captured-before-rebind
  $ cd "$ROOT/includes/captured-before-rebind"
  $ cat > source.ml <<'EOF'
  > exception Used = Not_found
  > exception Unused = Not_found
  > EOF
  $ ocamlc -w -a -bin-annot -c "$PWD/source.ml"
  $ cat > other.ml <<'EOF'
  > exception Used = Not_found
  > exception Unused = Not_found
  > EOF
  $ ocamlc -w -a -bin-annot -c "$PWD/other.ml"
  $ cat > relay.ml <<'EOF'
  > include Source
  > EOF
  $ ocamlc -w -a -bin-annot -c "$PWD/relay.ml"
  $ cat > wrapper.ml <<'EOF'
  > include Source
  > let saved () = raise Used
  > exception Used = Other.Used
  > EOF
  $ ocamlc -w -a -bin-annot -c "$PWD/wrapper.ml"
  $ cat > use.ml <<'EOF'
  > let () = raise (Wrapper.saved (); Wrapper.Used)
  > EOF
  $ ocamlc -w -a -bin-annot -c "$PWD/use.ml"
  $ reanalyze.exe -ci -debug -native-build-target . -dce-cmt . > analysis.out 2>/dev/null
  $ grep -m1 -oF -- 'Live Exception +source.Used:' analysis.out
  Live Exception +source.Used:
  $ grep -m1 -oF -- 'Dead Exception +source.Used:' analysis.out
  [1]
  $ grep -m1 -oF -- 'Live Exception +wrapper.Used:' analysis.out
  Live Exception +wrapper.Used:
  $ grep -m1 -oF -- 'Dead Exception +wrapper.Used:' analysis.out
  [1]
  $ grep -m1 -oF -- 'Dead Exception +source.Unused:' analysis.out
  Dead Exception +source.Unused:
  $ grep -m1 -oF -- 'Live Exception +source.Unused:' analysis.out
  [1]
  $ grep -m1 -oF -- 'Dead Exception +other.Unused:' analysis.out
  Dead Exception +other.Unused:
  $ grep -m1 -oF -- 'Live Exception +other.Unused:' analysis.out
  [1]

Case captured-constrained.

  $ mkdir -p ../captured-constrained
  $ cd "$ROOT/includes/captured-constrained"
  $ cat > source.ml <<'EOF'
  > exception Used = Not_found
  > exception Unused = Not_found
  > EOF
  $ ocamlc -w -a -bin-annot -c "$PWD/source.ml"
  $ cat > other.ml <<'EOF'
  > exception Used = Not_found
  > exception Unused = Not_found
  > EOF
  $ ocamlc -w -a -bin-annot -c "$PWD/other.ml"
  $ cat > relay.ml <<'EOF'
  > include Source
  > EOF
  $ ocamlc -w -a -bin-annot -c "$PWD/relay.ml"
  $ cat > wrapper.ml <<'EOF'
  > include (Source : sig exception Used exception Unused end)
  > let saved () = raise Used
  > include Other
  > EOF
  $ ocamlc -w -a -bin-annot -c "$PWD/wrapper.ml"
  $ cat > use.ml <<'EOF'
  > let () = raise (Wrapper.saved (); Not_found)
  > EOF
  $ ocamlc -w -a -bin-annot -c "$PWD/use.ml"
  $ reanalyze.exe -ci -debug -native-build-target . -dce-cmt . > analysis.out 2>/dev/null
  $ grep -m1 -oF -- 'Live Exception +source.Used:' analysis.out
  Live Exception +source.Used:
  $ grep -m1 -oF -- 'Dead Exception +source.Used:' analysis.out
  [1]
  $ grep -m1 -oF -- 'Dead Exception +other.Used:' analysis.out
  Dead Exception +other.Used:
  $ grep -m1 -oF -- 'Live Exception +other.Used:' analysis.out
  [1]
  $ grep -m1 -oF -- 'Dead Exception +source.Unused:' analysis.out
  Dead Exception +source.Unused:
  $ grep -m1 -oF -- 'Live Exception +source.Unused:' analysis.out
  [1]
  $ grep -m1 -oF -- 'Dead Exception +other.Unused:' analysis.out
  Dead Exception +other.Unused:
  $ grep -m1 -oF -- 'Live Exception +other.Unused:' analysis.out
  [1]

Case captured-constrained-both.

  $ mkdir -p ../captured-constrained-both
  $ cd "$ROOT/includes/captured-constrained-both"
  $ cat > source.ml <<'EOF'
  > exception Used = Not_found
  > exception Unused = Not_found
  > EOF
  $ ocamlc -w -a -bin-annot -c "$PWD/source.ml"
  $ cat > other.ml <<'EOF'
  > exception Used = Not_found
  > exception Unused = Not_found
  > EOF
  $ ocamlc -w -a -bin-annot -c "$PWD/other.ml"
  $ cat > relay.ml <<'EOF'
  > include Source
  > EOF
  $ ocamlc -w -a -bin-annot -c "$PWD/relay.ml"
  $ cat > wrapper.ml <<'EOF'
  > include struct include (Source : sig exception Used exception Unused end) end
  > let saved () = raise Used
  > include Other
  > EOF
  $ ocamlc -w -a -bin-annot -c "$PWD/wrapper.ml"
  $ cat > use.ml <<'EOF'
  > let () = raise (Wrapper.saved (); Wrapper.Used)
  > EOF
  $ ocamlc -w -a -bin-annot -c "$PWD/use.ml"
  $ reanalyze.exe -ci -debug -native-build-target . -dce-cmt . > analysis.out 2>/dev/null
  $ grep -m1 -oF -- 'Live Exception +source.Used:' analysis.out
  Live Exception +source.Used:
  $ grep -m1 -oF -- 'Dead Exception +source.Used:' analysis.out
  [1]
  $ grep -m1 -oF -- 'Live Exception +other.Used:' analysis.out
  Live Exception +other.Used:
  $ grep -m1 -oF -- 'Dead Exception +other.Used:' analysis.out
  [1]
  $ grep -m1 -oF -- 'Dead Exception +source.Unused:' analysis.out
  Dead Exception +source.Unused:
  $ grep -m1 -oF -- 'Live Exception +source.Unused:' analysis.out
  [1]
  $ grep -m1 -oF -- 'Dead Exception +other.Unused:' analysis.out
  Dead Exception +other.Unused:
  $ grep -m1 -oF -- 'Live Exception +other.Unused:' analysis.out
  [1]

Case qualified-constrained-local.

  $ mkdir -p ../qualified-constrained-local
  $ cd "$ROOT/includes/qualified-constrained-local"
  $ cat > source.ml <<'EOF'
  > exception Used = Not_found
  > exception Unused = Not_found
  > EOF
  $ ocamlc -w -a -bin-annot -c "$PWD/source.ml"
  $ cat > other.ml <<'EOF'
  > exception Used = Not_found
  > exception Unused = Not_found
  > EOF
  $ ocamlc -w -a -bin-annot -c "$PWD/other.ml"
  $ cat > relay.ml <<'EOF'
  > include Source
  > EOF
  $ ocamlc -w -a -bin-annot -c "$PWD/relay.ml"
  $ cat > wrapper.ml <<'EOF'
  > module M = struct include (Source : sig exception Used exception Unused end) end
  > let saved () = raise M.Used
  > EOF
  $ ocamlc -w -a -bin-annot -c "$PWD/wrapper.ml"
  $ cat > use.ml <<'EOF'
  > let () = raise (Wrapper.saved (); Not_found)
  > EOF
  $ ocamlc -w -a -bin-annot -c "$PWD/use.ml"
  $ reanalyze.exe -ci -debug -native-build-target . -dce-cmt . > analysis.out 2>/dev/null
  $ grep -m1 -oF -- 'Live Exception +source.Used:' analysis.out
  Live Exception +source.Used:
  $ grep -m1 -oF -- 'Dead Exception +source.Used:' analysis.out
  [1]
  $ grep -m1 -oF -- 'Dead Exception +other.Used:' analysis.out
  Dead Exception +other.Used:
  $ grep -m1 -oF -- 'Live Exception +other.Used:' analysis.out
  [1]
  $ grep -m1 -oF -- 'Dead Exception +source.Unused:' analysis.out
  Dead Exception +source.Unused:
  $ grep -m1 -oF -- 'Live Exception +source.Unused:' analysis.out
  [1]
  $ grep -m1 -oF -- 'Dead Exception +other.Unused:' analysis.out
  Dead Exception +other.Unused:
  $ grep -m1 -oF -- 'Live Exception +other.Unused:' analysis.out
  [1]

Case local-constructor.

  $ mkdir -p ../local-constructor
  $ cd "$ROOT/includes/local-constructor"
  $ cat > source.ml <<'EOF'
  > exception Used = Not_found
  > exception Unused = Not_found
  > EOF
  $ ocamlc -w -a -bin-annot -c "$PWD/source.ml"
  $ cat > other.ml <<'EOF'
  > exception Used = Not_found
  > exception Unused = Not_found
  > EOF
  $ ocamlc -w -a -bin-annot -c "$PWD/other.ml"
  $ cat > relay.ml <<'EOF'
  > include Source
  > EOF
  $ ocamlc -w -a -bin-annot -c "$PWD/relay.ml"
  $ cat > wrapper.ml <<'EOF'
  > include Source
  > let saved () = raise Used
  > EOF
  $ ocamlc -w -a -bin-annot -c "$PWD/wrapper.ml"
  $ cat > use.ml <<'EOF'
  > let () = raise (Wrapper.saved (); Not_found)
  > EOF
  $ ocamlc -w -a -bin-annot -c "$PWD/use.ml"
  $ reanalyze.exe -ci -debug -native-build-target . -dce-cmt . > analysis.out 2>/dev/null
  $ grep -m1 -oF -- 'Live Exception +source.Used:' analysis.out
  Live Exception +source.Used:
  $ grep -m1 -oF -- 'Dead Exception +source.Used:' analysis.out
  [1]
  $ grep -m1 -oF -- 'Dead Exception +other.Used:' analysis.out
  Dead Exception +other.Used:
  $ grep -m1 -oF -- 'Live Exception +other.Used:' analysis.out
  [1]
  $ grep -m1 -oF -- 'Dead Exception +source.Unused:' analysis.out
  Dead Exception +source.Unused:
  $ grep -m1 -oF -- 'Live Exception +source.Unused:' analysis.out
  [1]
  $ grep -m1 -oF -- 'Dead Exception +other.Unused:' analysis.out
  Dead Exception +other.Unused:
  $ grep -m1 -oF -- 'Live Exception +other.Unused:' analysis.out
  [1]

Case recursive.

  $ mkdir -p ../recursive
  $ cd "$ROOT/includes/recursive"
  $ cat > source.ml <<'EOF'
  > exception Used = Not_found
  > exception Unused = Not_found
  > EOF
  $ ocamlc -w -a -bin-annot -c "$PWD/source.ml"
  $ cat > other.ml <<'EOF'
  > exception Used = Not_found
  > exception Unused = Not_found
  > EOF
  $ ocamlc -w -a -bin-annot -c "$PWD/other.ml"
  $ cat > relay.ml <<'EOF'
  > include Source
  > EOF
  $ ocamlc -w -a -bin-annot -c "$PWD/relay.ml"
  $ cat > wrapper.ml <<'EOF'
  > module rec A : sig exception Used exception Unused end = struct include B end
  > and B : sig exception Used exception Unused end = struct include Source end
  > include A
  > EOF
  $ ocamlc -w -a -bin-annot -c "$PWD/wrapper.ml"
  $ cat > use.ml <<'EOF'
  > let () = raise Wrapper.Used
  > EOF
  $ ocamlc -w -a -bin-annot -c "$PWD/use.ml"
  $ reanalyze.exe -ci -debug -native-build-target . -dce-cmt . > analysis.out 2>/dev/null
  $ grep -m1 -oF -- 'Live Exception +source.Used:' analysis.out
  Live Exception +source.Used:
  $ grep -m1 -oF -- 'Dead Exception +source.Used:' analysis.out
  [1]
  $ grep -m1 -oF -- 'Dead Exception +other.Used:' analysis.out
  Dead Exception +other.Used:
  $ grep -m1 -oF -- 'Live Exception +other.Used:' analysis.out
  [1]
  $ grep -m1 -oF -- 'Dead Exception +source.Unused:' analysis.out
  Dead Exception +source.Unused:
  $ grep -m1 -oF -- 'Live Exception +source.Unused:' analysis.out
  [1]
  $ grep -m1 -oF -- 'Dead Exception +other.Unused:' analysis.out
  Dead Exception +other.Unused:
  $ grep -m1 -oF -- 'Live Exception +other.Unused:' analysis.out
  [1]

Case functor.

  $ mkdir -p ../functor
  $ cd "$ROOT/includes/functor"
  $ cat > source.ml <<'EOF'
  > exception Used = Not_found
  > exception Unused = Not_found
  > EOF
  $ ocamlc -w -a -bin-annot -c "$PWD/source.ml"
  $ cat > other.ml <<'EOF'
  > exception Used = Not_found
  > exception Unused = Not_found
  > EOF
  $ ocamlc -w -a -bin-annot -c "$PWD/other.ml"
  $ cat > relay.ml <<'EOF'
  > include Source
  > EOF
  $ ocamlc -w -a -bin-annot -c "$PWD/relay.ml"
  $ cat > wrapper.ml <<'EOF'
  > module F () = struct exception Used = Not_found
  > exception Unused = Not_found
  > end
  > include F ()
  > EOF
  $ ocamlc -w -a -bin-annot -c "$PWD/wrapper.ml"
  $ cat > use.ml <<'EOF'
  > let () = raise Wrapper.Used
  > EOF
  $ ocamlc -w -a -bin-annot -c "$PWD/use.ml"
  $ reanalyze.exe -ci -debug -native-build-target . -dce-cmt . > analysis.out 2>/dev/null
  $ grep -m1 -oF -- 'Live Exception +wrapper.F.Used:' analysis.out
  Live Exception +wrapper.F.Used:
  $ grep -m1 -oF -- 'Dead Exception +wrapper.F.Used:' analysis.out
  [1]
  $ grep -m1 -oF -- 'Dead Exception +wrapper.F.Unused:' analysis.out
  Dead Exception +wrapper.F.Unused:
  $ grep -m1 -oF -- 'Live Exception +wrapper.F.Unused:' analysis.out
  [1]
  $ grep -m1 -oF -- 'Dead Exception +source.Used:' analysis.out
  Dead Exception +source.Used:
  $ grep -m1 -oF -- 'Live Exception +source.Used:' analysis.out
  [1]
  $ grep -m1 -oF -- 'Dead Exception +other.Used:' analysis.out
  Dead Exception +other.Used:
  $ grep -m1 -oF -- 'Live Exception +other.Used:' analysis.out
  [1]
  $ grep -m1 -oF -- 'Dead Exception +source.Unused:' analysis.out
  Dead Exception +source.Unused:
  $ grep -m1 -oF -- 'Live Exception +source.Unused:' analysis.out
  [1]
  $ grep -m1 -oF -- 'Dead Exception +other.Unused:' analysis.out
  Dead Exception +other.Unused:
  $ grep -m1 -oF -- 'Live Exception +other.Unused:' analysis.out
  [1]

Case unused-include.

  $ mkdir -p ../unused-include
  $ cd "$ROOT/includes/unused-include"
  $ cat > source.ml <<'EOF'
  > exception Used = Not_found
  > exception Unused = Not_found
  > EOF
  $ ocamlc -w -a -bin-annot -c "$PWD/source.ml"
  $ cat > other.ml <<'EOF'
  > exception Used = Not_found
  > exception Unused = Not_found
  > EOF
  $ ocamlc -w -a -bin-annot -c "$PWD/other.ml"
  $ cat > relay.ml <<'EOF'
  > include Source
  > EOF
  $ ocamlc -w -a -bin-annot -c "$PWD/relay.ml"
  $ cat > wrapper.ml <<'EOF'
  > include Source
  > EOF
  $ ocamlc -w -a -bin-annot -c "$PWD/wrapper.ml"
  $ cat > use.ml <<'EOF'
  > let () = raise Not_found
  > EOF
  $ ocamlc -w -a -bin-annot -c "$PWD/use.ml"
  $ reanalyze.exe -ci -debug -native-build-target . -dce-cmt . > analysis.out 2>/dev/null
  $ grep -m1 -oF -- 'Dead Exception +source.Used:' analysis.out
  Dead Exception +source.Used:
  $ grep -m1 -oF -- 'Live Exception +source.Used:' analysis.out
  [1]
  $ grep -m1 -oF -- 'Dead Exception +other.Used:' analysis.out
  Dead Exception +other.Used:
  $ grep -m1 -oF -- 'Live Exception +other.Used:' analysis.out
  [1]
  $ grep -m1 -oF -- 'Dead Exception +source.Unused:' analysis.out
  Dead Exception +source.Unused:
  $ grep -m1 -oF -- 'Live Exception +source.Unused:' analysis.out
  [1]
  $ grep -m1 -oF -- 'Dead Exception +other.Unused:' analysis.out
  Dead Exception +other.Unused:
  $ grep -m1 -oF -- 'Live Exception +other.Unused:' analysis.out
  [1]

Exception usage counts constructor references even in an unused function.

  $ mkdir -p ../unused-function
  $ cd "$ROOT/includes/unused-function"
  $ cat > source.ml <<'EOF'
  > exception Used = Not_found
  > exception Unused = Not_found
  > EOF
  $ ocamlc -w -a -bin-annot -c "$PWD/source.ml"
  $ cat > other.ml <<'EOF'
  > exception Used = Not_found
  > exception Unused = Not_found
  > EOF
  $ ocamlc -w -a -bin-annot -c "$PWD/other.ml"
  $ cat > relay.ml <<'EOF'
  > include Source
  > EOF
  $ ocamlc -w -a -bin-annot -c "$PWD/relay.ml"
  $ cat > wrapper.ml <<'EOF'
  > include Source
  > let dead () = raise Used
  > EOF
  $ ocamlc -w -a -bin-annot -c "$PWD/wrapper.ml"
  $ cat > use.ml <<'EOF'
  > let () = raise Not_found
  > EOF
  $ ocamlc -w -a -bin-annot -c "$PWD/use.ml"
  $ reanalyze.exe -ci -debug -native-build-target . -dce-cmt . > analysis.out 2>/dev/null
  $ grep -m1 -oF -- 'Live Exception +source.Used:' analysis.out
  Live Exception +source.Used:
  $ grep -m1 -oF -- 'Dead Exception +source.Used:' analysis.out
  [1]
  $ grep -m1 -oF -- 'Dead Exception +other.Used:' analysis.out
  Dead Exception +other.Used:
  $ grep -m1 -oF -- 'Live Exception +other.Used:' analysis.out
  [1]
  $ grep -m1 -oF -- 'Dead Exception +source.Unused:' analysis.out
  Dead Exception +source.Unused:
  $ grep -m1 -oF -- 'Live Exception +source.Unused:' analysis.out
  [1]
  $ grep -m1 -oF -- 'Dead Exception +other.Unused:' analysis.out
  Dead Exception +other.Unused:
  $ grep -m1 -oF -- 'Live Exception +other.Unused:' analysis.out
  [1]

Case unused-function-qualified.

  $ mkdir -p ../unused-function-qualified
  $ cd "$ROOT/includes/unused-function-qualified"
  $ cat > source.ml <<'EOF'
  > exception Used = Not_found
  > exception Unused = Not_found
  > EOF
  $ ocamlc -w -a -bin-annot -c "$PWD/source.ml"
  $ cat > other.ml <<'EOF'
  > exception Used = Not_found
  > exception Unused = Not_found
  > EOF
  $ ocamlc -w -a -bin-annot -c "$PWD/other.ml"
  $ cat > relay.ml <<'EOF'
  > include Source
  > EOF
  $ ocamlc -w -a -bin-annot -c "$PWD/relay.ml"
  $ cat > wrapper.ml <<'EOF'
  > include Source
  > let dead () = raise Source.Used
  > EOF
  $ ocamlc -w -a -bin-annot -c "$PWD/wrapper.ml"
  $ cat > use.ml <<'EOF'
  > let () = raise Not_found
  > EOF
  $ ocamlc -w -a -bin-annot -c "$PWD/use.ml"
  $ reanalyze.exe -ci -debug -native-build-target . -dce-cmt . > analysis.out 2>/dev/null
  $ grep -m1 -oF -- 'Live Exception +source.Used:' analysis.out
  Live Exception +source.Used:
  $ grep -m1 -oF -- 'Dead Exception +source.Used:' analysis.out
  [1]
  $ grep -m1 -oF -- 'Dead Exception +other.Used:' analysis.out
  Dead Exception +other.Used:
  $ grep -m1 -oF -- 'Live Exception +other.Used:' analysis.out
  [1]
  $ grep -m1 -oF -- 'Dead Exception +source.Unused:' analysis.out
  Dead Exception +source.Unused:
  $ grep -m1 -oF -- 'Live Exception +source.Unused:' analysis.out
  [1]
  $ grep -m1 -oF -- 'Dead Exception +other.Unused:' analysis.out
  Dead Exception +other.Unused:
  $ grep -m1 -oF -- 'Live Exception +other.Unused:' analysis.out
  [1]

Case variant-overload.

  $ mkdir -p ../variant-overload
  $ cd "$ROOT/includes/variant-overload"
  $ cat > source.ml <<'EOF'
  > exception Used = Not_found
  > exception Unused = Not_found
  > EOF
  $ ocamlc -w -a -bin-annot -c "$PWD/source.ml"
  $ cat > other.ml <<'EOF'
  > exception Used = Not_found
  > exception Unused = Not_found
  > EOF
  $ ocamlc -w -a -bin-annot -c "$PWD/other.ml"
  $ cat > relay.ml <<'EOF'
  > include Source
  > EOF
  $ ocamlc -w -a -bin-annot -c "$PWD/relay.ml"
  $ cat > wrapper.ml <<'EOF'
  > include Source
  > type t = Used
  > EOF
  $ ocamlc -w -a -bin-annot -c "$PWD/wrapper.ml"
  $ cat > use.ml <<'EOF'
  > let () = raise Wrapper.Used
  > EOF
  $ ocamlc -w -a -bin-annot -c "$PWD/use.ml"
  $ reanalyze.exe -ci -debug -native-build-target . -dce-cmt . > analysis.out 2>/dev/null
  $ grep -m1 -oF -- 'Live Exception +source.Used:' analysis.out
  Live Exception +source.Used:
  $ grep -m1 -oF -- 'Dead Exception +source.Used:' analysis.out
  [1]
  $ grep -m1 -oF -- 'Dead Exception +other.Used:' analysis.out
  Dead Exception +other.Used:
  $ grep -m1 -oF -- 'Live Exception +other.Used:' analysis.out
  [1]
  $ grep -m1 -oF -- 'Dead Exception +source.Unused:' analysis.out
  Dead Exception +source.Unused:
  $ grep -m1 -oF -- 'Live Exception +source.Unused:' analysis.out
  [1]
  $ grep -m1 -oF -- 'Dead Exception +other.Unused:' analysis.out
  Dead Exception +other.Unused:
  $ grep -m1 -oF -- 'Live Exception +other.Unused:' analysis.out
  [1]

Case include-after-extension.

  $ mkdir -p ../include-after-extension
  $ cd "$ROOT/includes/include-after-extension"
  $ cat > source.ml <<'EOF'
  > exception Used = Not_found
  > exception Unused = Not_found
  > EOF
  $ ocamlc -w -a -bin-annot -c "$PWD/source.ml"
  $ cat > other.ml <<'EOF'
  > exception Used = Not_found
  > exception Unused = Not_found
  > EOF
  $ ocamlc -w -a -bin-annot -c "$PWD/other.ml"
  $ cat > relay.ml <<'EOF'
  > include Source
  > EOF
  $ ocamlc -w -a -bin-annot -c "$PWD/relay.ml"
  $ cat > wrapper.ml <<'EOF'
  > include struct type exn += Used end
  > include Source
  > EOF
  $ ocamlc -w -a -bin-annot -c "$PWD/wrapper.ml"
  $ cat > use.ml <<'EOF'
  > let () = raise Wrapper.Used
  > EOF
  $ ocamlc -w -a -bin-annot -c "$PWD/use.ml"
  $ reanalyze.exe -ci -debug -native-build-target . -dce-cmt . > analysis.out 2>/dev/null
  $ grep -m1 -oF -- 'Live Exception +source.Used:' analysis.out
  Live Exception +source.Used:
  $ grep -m1 -oF -- 'Dead Exception +source.Used:' analysis.out
  [1]
  $ grep -m1 -oF -- 'Dead Exception +other.Used:' analysis.out
  Dead Exception +other.Used:
  $ grep -m1 -oF -- 'Live Exception +other.Used:' analysis.out
  [1]
  $ grep -m1 -oF -- 'Dead Exception +source.Unused:' analysis.out
  Dead Exception +source.Unused:
  $ grep -m1 -oF -- 'Live Exception +source.Unused:' analysis.out
  [1]
  $ grep -m1 -oF -- 'Dead Exception +other.Unused:' analysis.out
  Dead Exception +other.Unused:
  $ grep -m1 -oF -- 'Live Exception +other.Unused:' analysis.out
  [1]

Case exception-after-extension.

  $ mkdir -p ../exception-after-extension
  $ cd "$ROOT/includes/exception-after-extension"
  $ cat > source.ml <<'EOF'
  > exception Used = Not_found
  > exception Unused = Not_found
  > EOF
  $ ocamlc -w -a -bin-annot -c "$PWD/source.ml"
  $ cat > other.ml <<'EOF'
  > exception Used = Not_found
  > exception Unused = Not_found
  > EOF
  $ ocamlc -w -a -bin-annot -c "$PWD/other.ml"
  $ cat > relay.ml <<'EOF'
  > include Source
  > EOF
  $ ocamlc -w -a -bin-annot -c "$PWD/relay.ml"
  $ cat > wrapper.ml <<'EOF'
  > include Source
  > include struct type exn += Used end
  > exception Used = Not_found
  > EOF
  $ ocamlc -w -a -bin-annot -c "$PWD/wrapper.ml"
  $ cat > use.ml <<'EOF'
  > let () = raise Wrapper.Used
  > EOF
  $ ocamlc -w -a -bin-annot -c "$PWD/use.ml"
  $ reanalyze.exe -ci -debug -native-build-target . -dce-cmt . > analysis.out 2>/dev/null
  $ grep -m1 -oF -- 'Live Exception +wrapper.Used:' analysis.out
  Live Exception +wrapper.Used:
  $ grep -m1 -oF -- 'Dead Exception +wrapper.Used:' analysis.out
  [1]
  $ grep -m1 -oF -- 'Dead Exception +source.Used:' analysis.out
  Dead Exception +source.Used:
  $ grep -m1 -oF -- 'Live Exception +source.Used:' analysis.out
  [1]
  $ grep -m1 -oF -- 'Dead Exception +other.Used:' analysis.out
  Dead Exception +other.Used:
  $ grep -m1 -oF -- 'Live Exception +other.Used:' analysis.out
  [1]
  $ grep -m1 -oF -- 'Dead Exception +source.Unused:' analysis.out
  Dead Exception +source.Unused:
  $ grep -m1 -oF -- 'Live Exception +source.Unused:' analysis.out
  [1]
  $ grep -m1 -oF -- 'Dead Exception +other.Unused:' analysis.out
  Dead Exception +other.Unused:
  $ grep -m1 -oF -- 'Live Exception +other.Unused:' analysis.out
  [1]

Dune's generated compilation-unit wrapper adds another alias hop.

  $ mkdir -p ../../wrapped-includes
  $ cd "$ROOT/wrapped-includes"
  $ cat > dune-project <<'EOF'
  > (lang dune 2.0)
  > (name included_exception)
  > EOF
  $ cat > dune <<'EOF'
  > (library (name included_exception) (modules source wrapper))
  > (executable (name main) (modules main) (libraries included_exception))
  > EOF
  $ cat > source.ml <<'EOF'
  > exception Used = Not_found
  > exception Unused = Not_found
  > EOF
  $ cat > wrapper.ml <<'EOF'
  > include Source
  > EOF
  $ cat > main.ml <<'EOF'
  > let () = raise Included_exception.Wrapper.Used
  > EOF
  $ dune build @check 2>&1
  $ reanalyze.exe -ci -debug -native-build-target . -dce-cmt _build > analysis.out 2>/dev/null
  $ grep -m1 -oF -- 'Live Exception +source.Used:' analysis.out
  Live Exception +source.Used:
  $ grep -m1 -oF -- 'Dead Exception +source.Used:' analysis.out
  [1]
  $ grep -m1 -oF -- 'Dead Exception +source.Unused:' analysis.out
  Dead Exception +source.Unused:
  $ grep -m1 -oF -- 'Live Exception +source.Unused:' analysis.out
  [1]

Include forwarding must preserve provider selection across artifact layouts.
Remove the build originals before analyzing from a neutral working directory.

  $ mkdir -p ../include-layouts/build
  $ cd "$ROOT/include-layouts/build"
  $ cat > source.ml <<'EOF'
  > exception Used = Not_found
  > exception Unused = Not_found
  > EOF
  $ ocamlc -w -a -bin-annot -c "$PWD/source.ml"
  $ cat > wrapper.mli <<'EOF'
  > include module type of Source
  > EOF
  $ ocamlc -w -a -bin-annot -c "$PWD/wrapper.mli"
  $ cat > wrapper.ml <<'EOF'
  > include Source
  > EOF
  $ ocamlc -w -a -bin-annot -c "$PWD/wrapper.ml"
  $ cat > use.ml <<'EOF'
  > let () = raise Wrapper.Used
  > EOF
  $ ocamlc -w -a -bin-annot -c "$PWD/use.ml"
  $ cd "$ROOT/include-layouts"
  $ mkdir -p alternate
  $ cp build/wrapper.cmi alternate

An explicit interface gives these distinct implementations the same digest.

  $ cd "$ROOT/include-layouts/alternate"
  $ cat > wrapper.mli <<'EOF'
  > include module type of Source
  > EOF
  $ cat > wrapper.ml <<'EOF'
  > include Source
  > let unused = ()
  > EOF
  $ ocamlc -w -a -bin-annot -I "$ROOT/include-layouts/build" -c "$PWD/wrapper.ml"
  $ cd "$ROOT/include-layouts"
  $ mkdir -p neutral

Layout colocated.

  $ mkdir -p colocated/one
  $ cp build/wrapper.cmti colocated/one
  $ cp build/wrapper.cmt colocated/one
  $ cp build/source.cmt colocated/one
  $ cp build/use.cmt colocated/one

Layout split.

  $ mkdir -p split/api
  $ cp build/wrapper.cmti split/api
  $ mkdir -p split/objects
  $ cp build/wrapper.cmt split/objects
  $ mkdir -p split/consumer
  $ cp build/source.cmt split/consumer
  $ cp build/use.cmt split/consumer

Layout beside-interface.

  $ mkdir -p beside-interface/api
  $ cp build/wrapper.cmti beside-interface/api
  $ mkdir -p beside-interface/objects
  $ cp build/wrapper.cmt beside-interface/objects
  $ cp build/source.cmt beside-interface/api
  $ cp build/use.cmt beside-interface/api

Layout beside-implementation.

  $ mkdir -p beside-implementation/api
  $ cp build/wrapper.cmti beside-implementation/api
  $ mkdir -p beside-implementation/objects
  $ cp build/wrapper.cmt beside-implementation/objects
  $ cp build/source.cmt beside-implementation/objects
  $ cp build/use.cmt beside-implementation/objects

Layout copies.

  $ mkdir -p copies/api
  $ cp build/wrapper.cmti copies/api
  $ mkdir -p copies/objects
  $ cp build/wrapper.cmt copies/objects
  $ mkdir -p copies/consumer
  $ cp build/source.cmt copies/consumer
  $ cp build/use.cmt copies/consumer
  $ mkdir -p copies/install/api
  $ cp build/wrapper.cmti copies/install/api
  $ mkdir -p copies/install/objects
  $ cp build/wrapper.cmt copies/install/objects
  $ mkdir -p copies/install/consumer
  $ cp build/source.cmt copies/install/consumer
  $ cp build/use.cmt copies/install/consumer

Layout competing.

  $ mkdir -p competing/api
  $ cp build/wrapper.cmti competing/api
  $ mkdir -p competing/objects
  $ cp build/wrapper.cmt competing/objects
  $ mkdir -p competing/consumer
  $ cp build/source.cmt competing/consumer
  $ cp build/use.cmt competing/consumer
  $ mkdir -p competing/other
  $ cp alternate/wrapper.cmt competing/other

Layout missing-wrapper.

  $ mkdir -p missing-wrapper/consumer
  $ cp build/source.cmt missing-wrapper/consumer
  $ cp build/use.cmt missing-wrapper/consumer

  $ rm -f build/*.cmt build/*.cmti build/*.cmi build/*.cmo
  $ rm -f alternate/*.cmt alternate/*.cmti alternate/*.cmi alternate/*.cmo

Layout colocated.

  $ cd "$ROOT/include-layouts/neutral"
  $ reanalyze.exe -ci -debug -native-build-target . -dce-cmt "$ROOT/include-layouts/colocated" > colocated.out 2>/dev/null
  $ grep -m1 -oF -- 'Live Exception +source.Used:' colocated.out
  Live Exception +source.Used:
  $ grep -m1 -oF -- 'Dead Exception +source.Used:' colocated.out
  [1]
  $ grep -m1 -oF -- 'Dead Exception +source.Unused:' colocated.out
  Dead Exception +source.Unused:
  $ grep -m1 -oF -- 'Live Exception +source.Unused:' colocated.out
  [1]

Layout split.

  $ reanalyze.exe -ci -debug -native-build-target . -dce-cmt "$ROOT/include-layouts/split" > split.out 2>/dev/null
  $ grep -m1 -oF -- 'Live Exception +source.Used:' split.out
  Live Exception +source.Used:
  $ grep -m1 -oF -- 'Dead Exception +source.Used:' split.out
  [1]
  $ grep -m1 -oF -- 'Dead Exception +source.Unused:' split.out
  Dead Exception +source.Unused:
  $ grep -m1 -oF -- 'Live Exception +source.Unused:' split.out
  [1]

Layout beside-interface.

  $ reanalyze.exe -ci -debug -native-build-target . -dce-cmt "$ROOT/include-layouts/beside-interface" > beside-interface.out 2>/dev/null
  $ grep -m1 -oF -- 'Live Exception +source.Used:' beside-interface.out
  Live Exception +source.Used:
  $ grep -m1 -oF -- 'Dead Exception +source.Used:' beside-interface.out
  [1]
  $ grep -m1 -oF -- 'Dead Exception +source.Unused:' beside-interface.out
  Dead Exception +source.Unused:
  $ grep -m1 -oF -- 'Live Exception +source.Unused:' beside-interface.out
  [1]

Layout beside-implementation.

  $ reanalyze.exe -ci -debug -native-build-target . -dce-cmt "$ROOT/include-layouts/beside-implementation" > beside-implementation.out 2>/dev/null
  $ grep -m1 -oF -- 'Live Exception +source.Used:' beside-implementation.out
  Live Exception +source.Used:
  $ grep -m1 -oF -- 'Dead Exception +source.Used:' beside-implementation.out
  [1]
  $ grep -m1 -oF -- 'Dead Exception +source.Unused:' beside-implementation.out
  Dead Exception +source.Unused:
  $ grep -m1 -oF -- 'Live Exception +source.Unused:' beside-implementation.out
  [1]

Layout copies.

  $ reanalyze.exe -ci -debug -native-build-target . -dce-cmt "$ROOT/include-layouts/copies" > copies.out 2>/dev/null
  $ grep -m1 -oF -- 'Live Exception +source.Used:' copies.out
  Live Exception +source.Used:
  $ grep -m1 -oF -- 'Dead Exception +source.Used:' copies.out
  [1]
  $ grep -m1 -oF -- 'Dead Exception +source.Unused:' copies.out
  Dead Exception +source.Unused:
  $ grep -m1 -oF -- 'Live Exception +source.Unused:' copies.out
  [1]

Layout competing: unresolved.

  $ reanalyze.exe -ci -debug -native-build-target . -dce-cmt "$ROOT/include-layouts/competing" > competing.out 2>/dev/null
  $ grep -m1 -oF -- 'Dead Exception +source.Used:' competing.out
  Dead Exception +source.Used:
  $ grep -m1 -oF -- 'Live Exception +source.Used:' competing.out
  [1]
  $ grep -m1 -oF -- 'Dead Exception +source.Unused:' competing.out
  Dead Exception +source.Unused:
  $ grep -m1 -oF -- 'Live Exception +source.Unused:' competing.out
  [1]

Layout missing-wrapper: unresolved.

  $ reanalyze.exe -ci -debug -native-build-target . -dce-cmt "$ROOT/include-layouts/missing-wrapper" > missing-wrapper.out 2>/dev/null
  $ grep -m1 -oF -- 'Dead Exception +source.Used:' missing-wrapper.out
  Dead Exception +source.Used:
  $ grep -m1 -oF -- 'Live Exception +source.Used:' missing-wrapper.out
  [1]
  $ grep -m1 -oF -- 'Dead Exception +source.Unused:' missing-wrapper.out
  Dead Exception +source.Unused:
  $ grep -m1 -oF -- 'Live Exception +source.Unused:' missing-wrapper.out
  [1]

Resolve each include using its own recorded imports. A same-named provider
with another digest must not stand in for a missing dependency.

  $ mkdir -p ../../include-digests
  $ cd "$ROOT/include-digests"
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
  $ mkdir -p one
  $ cd "$ROOT/include-digests/one"
  $ cat > source.ml <<'EOF'
  > include Left
  > let marker = 1
  > EOF
  $ ocamlc -w -a -bin-annot -I "$ROOT/include-digests" -c "$PWD/source.ml"
  $ mkdir -p ../two
  $ cd "$ROOT/include-digests/two"
  $ cat > source.ml <<'EOF'
  > include Right
  > let marker = true
  > EOF
  $ ocamlc -w -a -bin-annot -I "$ROOT/include-digests" -c "$PWD/source.ml"
  $ cd "$ROOT/include-digests/one"
  $ cat > wrapper.ml <<'EOF'
  > include Source
  > EOF
  $ ocamlc -w -a -bin-annot -I "$ROOT/include-digests" -c "$PWD/wrapper.ml"
  $ cd "$ROOT/include-digests/two"
  $ cat > wrapper.ml <<'EOF'
  > include Source
  > EOF
  $ ocamlc -w -a -bin-annot -I "$ROOT/include-digests" -c "$PWD/wrapper.ml"
  $ mkdir -p ../consumer
  $ cd "$ROOT/include-digests/consumer"
  $ cat > use.ml <<'EOF'
  > let () = raise Wrapper.Used
  > EOF
  $ ocamlc -w -a -bin-annot -I "$ROOT/include-digests/one" -I "$ROOT/include-digests" -c "$PWD/use.ml"
  $ cd "$ROOT/include-digests"

Layout forward.

  $ mkdir -p forward/consumer
  $ cp left.cmt forward/consumer
  $ cp right.cmt forward/consumer
  $ cp consumer/use.cmt forward/consumer
  $ mkdir -p forward/a
  $ cp one/wrapper.cmt forward/a
  $ mkdir -p forward/z
  $ cp two/wrapper.cmt forward/z
  $ mkdir -p forward/y
  $ cp one/source.cmt forward/y
  $ mkdir -p forward/b
  $ cp two/source.cmt forward/b

Layout reverse.

  $ mkdir -p reverse/consumer
  $ cp left.cmt reverse/consumer
  $ cp right.cmt reverse/consumer
  $ cp consumer/use.cmt reverse/consumer
  $ mkdir -p reverse/z
  $ cp one/wrapper.cmt reverse/z
  $ mkdir -p reverse/a
  $ cp two/wrapper.cmt reverse/a
  $ mkdir -p reverse/b
  $ cp one/source.cmt reverse/b
  $ mkdir -p reverse/y
  $ cp two/source.cmt reverse/y

Layout missing-wrapper.

  $ mkdir -p missing-wrapper/consumer
  $ cp left.cmt missing-wrapper/consumer
  $ cp right.cmt missing-wrapper/consumer
  $ cp consumer/use.cmt missing-wrapper/consumer
  $ mkdir -p missing-wrapper/z
  $ cp two/wrapper.cmt missing-wrapper/z
  $ mkdir -p missing-wrapper/y
  $ cp one/source.cmt missing-wrapper/y
  $ mkdir -p missing-wrapper/b
  $ cp two/source.cmt missing-wrapper/b

Layout missing-source.

  $ mkdir -p missing-source/consumer
  $ cp left.cmt missing-source/consumer
  $ cp right.cmt missing-source/consumer
  $ cp consumer/use.cmt missing-source/consumer
  $ mkdir -p missing-source/a
  $ cp one/wrapper.cmt missing-source/a
  $ mkdir -p missing-source/z
  $ cp two/wrapper.cmt missing-source/z
  $ mkdir -p missing-source/b
  $ cp two/source.cmt missing-source/b

  $ rm -f ./*.cmt ./*.cmti ./*.cmi ./*.cmo
  $ rm -f one/*.cmt one/*.cmti one/*.cmi one/*.cmo
  $ rm -f two/*.cmt two/*.cmti two/*.cmi two/*.cmo
  $ rm -f consumer/*.cmt consumer/*.cmti consumer/*.cmi consumer/*.cmo

Layout forward.

  $ cd "$ROOT/include-layouts/neutral"
  $ reanalyze.exe -ci -debug -native-build-target . -dce-cmt "$ROOT/include-digests/forward" > digests-forward.out 2>/dev/null
  $ grep -m1 -oF -- 'Live Exception +left.Used:' digests-forward.out
  Live Exception +left.Used:
  $ grep -m1 -oF -- 'Dead Exception +left.Used:' digests-forward.out
  [1]
  $ grep -m1 -oF -- 'Dead Exception +left.Unused:' digests-forward.out
  Dead Exception +left.Unused:
  $ grep -m1 -oF -- 'Live Exception +left.Unused:' digests-forward.out
  [1]
  $ grep -m1 -oF -- 'Dead Exception +right.Unused:' digests-forward.out
  Dead Exception +right.Unused:
  $ grep -m1 -oF -- 'Live Exception +right.Unused:' digests-forward.out
  [1]
  $ grep -m1 -oF -- 'Dead Exception +right.Used:' digests-forward.out
  Dead Exception +right.Used:
  $ grep -m1 -oF -- 'Live Exception +right.Used:' digests-forward.out
  [1]

Layout reverse.

  $ reanalyze.exe -ci -debug -native-build-target . -dce-cmt "$ROOT/include-digests/reverse" > digests-reverse.out 2>/dev/null
  $ grep -m1 -oF -- 'Live Exception +left.Used:' digests-reverse.out
  Live Exception +left.Used:
  $ grep -m1 -oF -- 'Dead Exception +left.Used:' digests-reverse.out
  [1]
  $ grep -m1 -oF -- 'Dead Exception +left.Unused:' digests-reverse.out
  Dead Exception +left.Unused:
  $ grep -m1 -oF -- 'Live Exception +left.Unused:' digests-reverse.out
  [1]
  $ grep -m1 -oF -- 'Dead Exception +right.Unused:' digests-reverse.out
  Dead Exception +right.Unused:
  $ grep -m1 -oF -- 'Live Exception +right.Unused:' digests-reverse.out
  [1]
  $ grep -m1 -oF -- 'Dead Exception +right.Used:' digests-reverse.out
  Dead Exception +right.Used:
  $ grep -m1 -oF -- 'Live Exception +right.Used:' digests-reverse.out
  [1]

Layout missing-wrapper.

  $ reanalyze.exe -ci -debug -native-build-target . -dce-cmt "$ROOT/include-digests/missing-wrapper" > digests-missing-wrapper.out 2>/dev/null
  $ grep -m1 -oF -- 'Dead Exception +left.Unused:' digests-missing-wrapper.out
  Dead Exception +left.Unused:
  $ grep -m1 -oF -- 'Live Exception +left.Unused:' digests-missing-wrapper.out
  [1]
  $ grep -m1 -oF -- 'Dead Exception +right.Unused:' digests-missing-wrapper.out
  Dead Exception +right.Unused:
  $ grep -m1 -oF -- 'Live Exception +right.Unused:' digests-missing-wrapper.out
  [1]
  $ grep -m1 -oF -- 'Dead Exception +right.Used:' digests-missing-wrapper.out
  Dead Exception +right.Used:
  $ grep -m1 -oF -- 'Live Exception +right.Used:' digests-missing-wrapper.out
  [1]
  $ grep -m1 -oF -- 'Dead Exception +left.Used:' digests-missing-wrapper.out
  Dead Exception +left.Used:
  $ grep -m1 -oF -- 'Live Exception +left.Used:' digests-missing-wrapper.out
  [1]

Layout missing-source.

  $ reanalyze.exe -ci -debug -native-build-target . -dce-cmt "$ROOT/include-digests/missing-source" > digests-missing-source.out 2>/dev/null
  $ grep -m1 -oF -- 'Dead Exception +left.Unused:' digests-missing-source.out
  Dead Exception +left.Unused:
  $ grep -m1 -oF -- 'Live Exception +left.Unused:' digests-missing-source.out
  [1]
  $ grep -m1 -oF -- 'Dead Exception +right.Unused:' digests-missing-source.out
  Dead Exception +right.Unused:
  $ grep -m1 -oF -- 'Live Exception +right.Unused:' digests-missing-source.out
  [1]
  $ grep -m1 -oF -- 'Dead Exception +right.Used:' digests-missing-source.out
  Dead Exception +right.Used:
  $ grep -m1 -oF -- 'Live Exception +right.Used:' digests-missing-source.out
  [1]
  $ grep -m1 -oF -- 'Dead Exception +left.Used:' digests-missing-source.out
  Dead Exception +left.Used:
  $ grep -m1 -oF -- 'Live Exception +left.Used:' digests-missing-source.out
  [1]
