All extension constructors share exported names with exceptions. A later
extension must hide the old export without changing an earlier capture.

Each case lives in its own directory EXCEPTION_TYPE-CONSTRAINED-CAPTURE-REPLACEMENT:
the extended type is exn or a type t, the include of Source is constrained
or not, Wrapper captures Used before the replacement or not, and the
replacement is a direct extension, an include, a rebind or a constrained
include.

  $ ROOT=$PWD

Case false-false-false-direct.

  $ mkdir -p extension-shadow/false-false-false-direct
  $ cd "$ROOT/extension-shadow/false-false-false-direct"
  $ cat > source.ml <<'EOF'
  > exception Used = Not_found
  > exception Unused = Not_found
  > EOF
  $ ocamlc -w -a -bin-annot -c "$PWD/source.ml"
  $ cat > ext.ml <<'EOF'
  > type t = ..
  > type t += Used | Other
  > EOF
  $ ocamlc -w -a -bin-annot -c "$PWD/ext.ml"
  $ cat > wrapper.ml <<'EOF'
  > include Source
  > type t = ..
  > type t += Used | Other
  > EOF
  $ ocamlc -w -a -bin-annot -c "$PWD/wrapper.ml"
  $ cat > bridge.ml <<'EOF'
  > module Alias = Wrapper
  > EOF
  $ ocamlc -w -a -bin-annot -c "$PWD/bridge.ml"
  $ cat > use.ml <<'EOF'
  > let () = ignore (Wrapper.Used : Wrapper.t); ignore (Bridge.Alias.Used : Wrapper.t)
  > EOF
  $ ocamlc -w -a -bin-annot -c "$PWD/use.ml"
  $ reanalyze.exe -ci -debug -native-build-target . -dce-cmt . > analysis.out 2>/dev/null
  $ grep -m1 -oF -- 'Dead Exception +source.Used:' analysis.out
  Dead Exception +source.Used:
  $ grep -m1 -oF -- 'Live Exception +source.Used:' analysis.out
  [1]
  $ grep -m1 -oF -- 'Dead Exception +source.Unused:' analysis.out
  Dead Exception +source.Unused:
  $ grep -m1 -oF -- 'Live Exception +source.Unused:' analysis.out
  [1]

Case false-false-false-include.

  $ mkdir -p ../false-false-false-include
  $ cd "$ROOT/extension-shadow/false-false-false-include"
  $ cat > source.ml <<'EOF'
  > exception Used = Not_found
  > exception Unused = Not_found
  > EOF
  $ ocamlc -w -a -bin-annot -c "$PWD/source.ml"
  $ cat > ext.ml <<'EOF'
  > type t = ..
  > type t += Used | Other
  > EOF
  $ ocamlc -w -a -bin-annot -c "$PWD/ext.ml"
  $ cat > wrapper.ml <<'EOF'
  > include Source
  > include Ext
  > EOF
  $ ocamlc -w -a -bin-annot -c "$PWD/wrapper.ml"
  $ cat > bridge.ml <<'EOF'
  > module Alias = Wrapper
  > EOF
  $ ocamlc -w -a -bin-annot -c "$PWD/bridge.ml"
  $ cat > use.ml <<'EOF'
  > let () = ignore (Wrapper.Used : Wrapper.t); ignore (Bridge.Alias.Used : Wrapper.t)
  > EOF
  $ ocamlc -w -a -bin-annot -c "$PWD/use.ml"
  $ reanalyze.exe -ci -debug -native-build-target . -dce-cmt . > analysis.out 2>/dev/null
  $ grep -m1 -oF -- 'Dead Exception +source.Used:' analysis.out
  Dead Exception +source.Used:
  $ grep -m1 -oF -- 'Live Exception +source.Used:' analysis.out
  [1]
  $ grep -m1 -oF -- 'Dead Exception +source.Unused:' analysis.out
  Dead Exception +source.Unused:
  $ grep -m1 -oF -- 'Live Exception +source.Unused:' analysis.out
  [1]

Case false-false-false-rebind.

  $ mkdir -p ../false-false-false-rebind
  $ cd "$ROOT/extension-shadow/false-false-false-rebind"
  $ cat > source.ml <<'EOF'
  > exception Used = Not_found
  > exception Unused = Not_found
  > EOF
  $ ocamlc -w -a -bin-annot -c "$PWD/source.ml"
  $ cat > ext.ml <<'EOF'
  > type t = ..
  > type t += Used | Other
  > EOF
  $ ocamlc -w -a -bin-annot -c "$PWD/ext.ml"
  $ cat > wrapper.ml <<'EOF'
  > include Source
  > type Ext.t += Used = Ext.Other
  > EOF
  $ ocamlc -w -a -bin-annot -c "$PWD/wrapper.ml"
  $ cat > bridge.ml <<'EOF'
  > module Alias = Wrapper
  > EOF
  $ ocamlc -w -a -bin-annot -c "$PWD/bridge.ml"
  $ cat > use.ml <<'EOF'
  > let () = ignore (Wrapper.Used : Ext.t); ignore (Bridge.Alias.Used : Ext.t)
  > EOF
  $ ocamlc -w -a -bin-annot -c "$PWD/use.ml"
  $ reanalyze.exe -ci -debug -native-build-target . -dce-cmt . > analysis.out 2>/dev/null
  $ grep -m1 -oF -- 'Dead Exception +source.Used:' analysis.out
  Dead Exception +source.Used:
  $ grep -m1 -oF -- 'Live Exception +source.Used:' analysis.out
  [1]
  $ grep -m1 -oF -- 'Dead Exception +source.Unused:' analysis.out
  Dead Exception +source.Unused:
  $ grep -m1 -oF -- 'Live Exception +source.Unused:' analysis.out
  [1]

Case false-false-false-constrained-include.

  $ mkdir -p ../false-false-false-constrained-include
  $ cd "$ROOT/extension-shadow/false-false-false-constrained-include"
  $ cat > source.ml <<'EOF'
  > exception Used = Not_found
  > exception Unused = Not_found
  > EOF
  $ ocamlc -w -a -bin-annot -c "$PWD/source.ml"
  $ cat > ext.ml <<'EOF'
  > type t = ..
  > type t += Used | Other
  > EOF
  $ ocamlc -w -a -bin-annot -c "$PWD/ext.ml"
  $ cat > wrapper.ml <<'EOF'
  > include Source
  > include (Ext : sig type t = .. type t += Used end)
  > EOF
  $ ocamlc -w -a -bin-annot -c "$PWD/wrapper.ml"
  $ cat > bridge.ml <<'EOF'
  > module Alias = Wrapper
  > EOF
  $ ocamlc -w -a -bin-annot -c "$PWD/bridge.ml"
  $ cat > use.ml <<'EOF'
  > let () = ignore (Wrapper.Used : Wrapper.t); ignore (Bridge.Alias.Used : Wrapper.t)
  > EOF
  $ ocamlc -w -a -bin-annot -c "$PWD/use.ml"
  $ reanalyze.exe -ci -debug -native-build-target . -dce-cmt . > analysis.out 2>/dev/null
  $ grep -m1 -oF -- 'Dead Exception +source.Used:' analysis.out
  Dead Exception +source.Used:
  $ grep -m1 -oF -- 'Live Exception +source.Used:' analysis.out
  [1]
  $ grep -m1 -oF -- 'Dead Exception +source.Unused:' analysis.out
  Dead Exception +source.Unused:
  $ grep -m1 -oF -- 'Live Exception +source.Unused:' analysis.out
  [1]

Case false-false-true-direct.

  $ mkdir -p ../false-false-true-direct
  $ cd "$ROOT/extension-shadow/false-false-true-direct"
  $ cat > source.ml <<'EOF'
  > exception Used = Not_found
  > exception Unused = Not_found
  > EOF
  $ ocamlc -w -a -bin-annot -c "$PWD/source.ml"
  $ cat > ext.ml <<'EOF'
  > type t = ..
  > type t += Used | Other
  > EOF
  $ ocamlc -w -a -bin-annot -c "$PWD/ext.ml"
  $ cat > wrapper.ml <<'EOF'
  > include Source
  > let saved () = raise Used
  > type t = ..
  > type t += Used | Other
  > EOF
  $ ocamlc -w -a -bin-annot -c "$PWD/wrapper.ml"
  $ cat > bridge.ml <<'EOF'
  > module Alias = Wrapper
  > EOF
  $ ocamlc -w -a -bin-annot -c "$PWD/bridge.ml"
  $ cat > use.ml <<'EOF'
  > let () = Wrapper.saved ()
  > let () = ignore (Wrapper.Used : Wrapper.t); ignore (Bridge.Alias.Used : Wrapper.t)
  > EOF
  $ ocamlc -w -a -bin-annot -c "$PWD/use.ml"
  $ reanalyze.exe -ci -debug -native-build-target . -dce-cmt . > analysis.out 2>/dev/null
  $ grep -m1 -oF -- 'Live Exception +source.Used:' analysis.out
  Live Exception +source.Used:
  $ grep -m1 -oF -- 'Dead Exception +source.Used:' analysis.out
  [1]
  $ grep -m1 -oF -- 'Dead Exception +source.Unused:' analysis.out
  Dead Exception +source.Unused:
  $ grep -m1 -oF -- 'Live Exception +source.Unused:' analysis.out
  [1]

Case false-false-true-include.

  $ mkdir -p ../false-false-true-include
  $ cd "$ROOT/extension-shadow/false-false-true-include"
  $ cat > source.ml <<'EOF'
  > exception Used = Not_found
  > exception Unused = Not_found
  > EOF
  $ ocamlc -w -a -bin-annot -c "$PWD/source.ml"
  $ cat > ext.ml <<'EOF'
  > type t = ..
  > type t += Used | Other
  > EOF
  $ ocamlc -w -a -bin-annot -c "$PWD/ext.ml"
  $ cat > wrapper.ml <<'EOF'
  > include Source
  > let saved () = raise Used
  > include Ext
  > EOF
  $ ocamlc -w -a -bin-annot -c "$PWD/wrapper.ml"
  $ cat > bridge.ml <<'EOF'
  > module Alias = Wrapper
  > EOF
  $ ocamlc -w -a -bin-annot -c "$PWD/bridge.ml"
  $ cat > use.ml <<'EOF'
  > let () = Wrapper.saved ()
  > let () = ignore (Wrapper.Used : Wrapper.t); ignore (Bridge.Alias.Used : Wrapper.t)
  > EOF
  $ ocamlc -w -a -bin-annot -c "$PWD/use.ml"
  $ reanalyze.exe -ci -debug -native-build-target . -dce-cmt . > analysis.out 2>/dev/null
  $ grep -m1 -oF -- 'Live Exception +source.Used:' analysis.out
  Live Exception +source.Used:
  $ grep -m1 -oF -- 'Dead Exception +source.Used:' analysis.out
  [1]
  $ grep -m1 -oF -- 'Dead Exception +source.Unused:' analysis.out
  Dead Exception +source.Unused:
  $ grep -m1 -oF -- 'Live Exception +source.Unused:' analysis.out
  [1]

Case false-false-true-rebind.

  $ mkdir -p ../false-false-true-rebind
  $ cd "$ROOT/extension-shadow/false-false-true-rebind"
  $ cat > source.ml <<'EOF'
  > exception Used = Not_found
  > exception Unused = Not_found
  > EOF
  $ ocamlc -w -a -bin-annot -c "$PWD/source.ml"
  $ cat > ext.ml <<'EOF'
  > type t = ..
  > type t += Used | Other
  > EOF
  $ ocamlc -w -a -bin-annot -c "$PWD/ext.ml"
  $ cat > wrapper.ml <<'EOF'
  > include Source
  > let saved () = raise Used
  > type Ext.t += Used = Ext.Other
  > EOF
  $ ocamlc -w -a -bin-annot -c "$PWD/wrapper.ml"
  $ cat > bridge.ml <<'EOF'
  > module Alias = Wrapper
  > EOF
  $ ocamlc -w -a -bin-annot -c "$PWD/bridge.ml"
  $ cat > use.ml <<'EOF'
  > let () = Wrapper.saved ()
  > let () = ignore (Wrapper.Used : Ext.t); ignore (Bridge.Alias.Used : Ext.t)
  > EOF
  $ ocamlc -w -a -bin-annot -c "$PWD/use.ml"
  $ reanalyze.exe -ci -debug -native-build-target . -dce-cmt . > analysis.out 2>/dev/null
  $ grep -m1 -oF -- 'Live Exception +source.Used:' analysis.out
  Live Exception +source.Used:
  $ grep -m1 -oF -- 'Dead Exception +source.Used:' analysis.out
  [1]
  $ grep -m1 -oF -- 'Dead Exception +source.Unused:' analysis.out
  Dead Exception +source.Unused:
  $ grep -m1 -oF -- 'Live Exception +source.Unused:' analysis.out
  [1]

Case false-false-true-constrained-include.

  $ mkdir -p ../false-false-true-constrained-include
  $ cd "$ROOT/extension-shadow/false-false-true-constrained-include"
  $ cat > source.ml <<'EOF'
  > exception Used = Not_found
  > exception Unused = Not_found
  > EOF
  $ ocamlc -w -a -bin-annot -c "$PWD/source.ml"
  $ cat > ext.ml <<'EOF'
  > type t = ..
  > type t += Used | Other
  > EOF
  $ ocamlc -w -a -bin-annot -c "$PWD/ext.ml"
  $ cat > wrapper.ml <<'EOF'
  > include Source
  > let saved () = raise Used
  > include (Ext : sig type t = .. type t += Used end)
  > EOF
  $ ocamlc -w -a -bin-annot -c "$PWD/wrapper.ml"
  $ cat > bridge.ml <<'EOF'
  > module Alias = Wrapper
  > EOF
  $ ocamlc -w -a -bin-annot -c "$PWD/bridge.ml"
  $ cat > use.ml <<'EOF'
  > let () = Wrapper.saved ()
  > let () = ignore (Wrapper.Used : Wrapper.t); ignore (Bridge.Alias.Used : Wrapper.t)
  > EOF
  $ ocamlc -w -a -bin-annot -c "$PWD/use.ml"
  $ reanalyze.exe -ci -debug -native-build-target . -dce-cmt . > analysis.out 2>/dev/null
  $ grep -m1 -oF -- 'Live Exception +source.Used:' analysis.out
  Live Exception +source.Used:
  $ grep -m1 -oF -- 'Dead Exception +source.Used:' analysis.out
  [1]
  $ grep -m1 -oF -- 'Dead Exception +source.Unused:' analysis.out
  Dead Exception +source.Unused:
  $ grep -m1 -oF -- 'Live Exception +source.Unused:' analysis.out
  [1]

Case false-true-false-direct.

  $ mkdir -p ../false-true-false-direct
  $ cd "$ROOT/extension-shadow/false-true-false-direct"
  $ cat > source.ml <<'EOF'
  > exception Used = Not_found
  > exception Unused = Not_found
  > EOF
  $ ocamlc -w -a -bin-annot -c "$PWD/source.ml"
  $ cat > ext.ml <<'EOF'
  > type t = ..
  > type t += Used | Other
  > EOF
  $ ocamlc -w -a -bin-annot -c "$PWD/ext.ml"
  $ cat > wrapper.ml <<'EOF'
  > include (Source : sig exception Used exception Unused end)
  > type t = ..
  > type t += Used | Other
  > EOF
  $ ocamlc -w -a -bin-annot -c "$PWD/wrapper.ml"
  $ cat > bridge.ml <<'EOF'
  > module Alias = Wrapper
  > EOF
  $ ocamlc -w -a -bin-annot -c "$PWD/bridge.ml"
  $ cat > use.ml <<'EOF'
  > let () = ignore (Wrapper.Used : Wrapper.t); ignore (Bridge.Alias.Used : Wrapper.t)
  > EOF
  $ ocamlc -w -a -bin-annot -c "$PWD/use.ml"
  $ reanalyze.exe -ci -debug -native-build-target . -dce-cmt . > analysis.out 2>/dev/null
  $ grep -m1 -oF -- 'Dead Exception +source.Used:' analysis.out
  Dead Exception +source.Used:
  $ grep -m1 -oF -- 'Live Exception +source.Used:' analysis.out
  [1]
  $ grep -m1 -oF -- 'Dead Exception +source.Unused:' analysis.out
  Dead Exception +source.Unused:
  $ grep -m1 -oF -- 'Live Exception +source.Unused:' analysis.out
  [1]

Case false-true-false-include.

  $ mkdir -p ../false-true-false-include
  $ cd "$ROOT/extension-shadow/false-true-false-include"
  $ cat > source.ml <<'EOF'
  > exception Used = Not_found
  > exception Unused = Not_found
  > EOF
  $ ocamlc -w -a -bin-annot -c "$PWD/source.ml"
  $ cat > ext.ml <<'EOF'
  > type t = ..
  > type t += Used | Other
  > EOF
  $ ocamlc -w -a -bin-annot -c "$PWD/ext.ml"
  $ cat > wrapper.ml <<'EOF'
  > include (Source : sig exception Used exception Unused end)
  > include Ext
  > EOF
  $ ocamlc -w -a -bin-annot -c "$PWD/wrapper.ml"
  $ cat > bridge.ml <<'EOF'
  > module Alias = Wrapper
  > EOF
  $ ocamlc -w -a -bin-annot -c "$PWD/bridge.ml"
  $ cat > use.ml <<'EOF'
  > let () = ignore (Wrapper.Used : Wrapper.t); ignore (Bridge.Alias.Used : Wrapper.t)
  > EOF
  $ ocamlc -w -a -bin-annot -c "$PWD/use.ml"
  $ reanalyze.exe -ci -debug -native-build-target . -dce-cmt . > analysis.out 2>/dev/null
  $ grep -m1 -oF -- 'Dead Exception +source.Used:' analysis.out
  Dead Exception +source.Used:
  $ grep -m1 -oF -- 'Live Exception +source.Used:' analysis.out
  [1]
  $ grep -m1 -oF -- 'Dead Exception +source.Unused:' analysis.out
  Dead Exception +source.Unused:
  $ grep -m1 -oF -- 'Live Exception +source.Unused:' analysis.out
  [1]

Case false-true-false-rebind.

  $ mkdir -p ../false-true-false-rebind
  $ cd "$ROOT/extension-shadow/false-true-false-rebind"
  $ cat > source.ml <<'EOF'
  > exception Used = Not_found
  > exception Unused = Not_found
  > EOF
  $ ocamlc -w -a -bin-annot -c "$PWD/source.ml"
  $ cat > ext.ml <<'EOF'
  > type t = ..
  > type t += Used | Other
  > EOF
  $ ocamlc -w -a -bin-annot -c "$PWD/ext.ml"
  $ cat > wrapper.ml <<'EOF'
  > include (Source : sig exception Used exception Unused end)
  > type Ext.t += Used = Ext.Other
  > EOF
  $ ocamlc -w -a -bin-annot -c "$PWD/wrapper.ml"
  $ cat > bridge.ml <<'EOF'
  > module Alias = Wrapper
  > EOF
  $ ocamlc -w -a -bin-annot -c "$PWD/bridge.ml"
  $ cat > use.ml <<'EOF'
  > let () = ignore (Wrapper.Used : Ext.t); ignore (Bridge.Alias.Used : Ext.t)
  > EOF
  $ ocamlc -w -a -bin-annot -c "$PWD/use.ml"
  $ reanalyze.exe -ci -debug -native-build-target . -dce-cmt . > analysis.out 2>/dev/null
  $ grep -m1 -oF -- 'Dead Exception +source.Used:' analysis.out
  Dead Exception +source.Used:
  $ grep -m1 -oF -- 'Live Exception +source.Used:' analysis.out
  [1]
  $ grep -m1 -oF -- 'Dead Exception +source.Unused:' analysis.out
  Dead Exception +source.Unused:
  $ grep -m1 -oF -- 'Live Exception +source.Unused:' analysis.out
  [1]

Case false-true-false-constrained-include.

  $ mkdir -p ../false-true-false-constrained-include
  $ cd "$ROOT/extension-shadow/false-true-false-constrained-include"
  $ cat > source.ml <<'EOF'
  > exception Used = Not_found
  > exception Unused = Not_found
  > EOF
  $ ocamlc -w -a -bin-annot -c "$PWD/source.ml"
  $ cat > ext.ml <<'EOF'
  > type t = ..
  > type t += Used | Other
  > EOF
  $ ocamlc -w -a -bin-annot -c "$PWD/ext.ml"
  $ cat > wrapper.ml <<'EOF'
  > include (Source : sig exception Used exception Unused end)
  > include (Ext : sig type t = .. type t += Used end)
  > EOF
  $ ocamlc -w -a -bin-annot -c "$PWD/wrapper.ml"
  $ cat > bridge.ml <<'EOF'
  > module Alias = Wrapper
  > EOF
  $ ocamlc -w -a -bin-annot -c "$PWD/bridge.ml"
  $ cat > use.ml <<'EOF'
  > let () = ignore (Wrapper.Used : Wrapper.t); ignore (Bridge.Alias.Used : Wrapper.t)
  > EOF
  $ ocamlc -w -a -bin-annot -c "$PWD/use.ml"
  $ reanalyze.exe -ci -debug -native-build-target . -dce-cmt . > analysis.out 2>/dev/null
  $ grep -m1 -oF -- 'Dead Exception +source.Used:' analysis.out
  Dead Exception +source.Used:
  $ grep -m1 -oF -- 'Live Exception +source.Used:' analysis.out
  [1]
  $ grep -m1 -oF -- 'Dead Exception +source.Unused:' analysis.out
  Dead Exception +source.Unused:
  $ grep -m1 -oF -- 'Live Exception +source.Unused:' analysis.out
  [1]

Case false-true-true-direct.

  $ mkdir -p ../false-true-true-direct
  $ cd "$ROOT/extension-shadow/false-true-true-direct"
  $ cat > source.ml <<'EOF'
  > exception Used = Not_found
  > exception Unused = Not_found
  > EOF
  $ ocamlc -w -a -bin-annot -c "$PWD/source.ml"
  $ cat > ext.ml <<'EOF'
  > type t = ..
  > type t += Used | Other
  > EOF
  $ ocamlc -w -a -bin-annot -c "$PWD/ext.ml"
  $ cat > wrapper.ml <<'EOF'
  > include (Source : sig exception Used exception Unused end)
  > let saved () = raise Used
  > type t = ..
  > type t += Used | Other
  > EOF
  $ ocamlc -w -a -bin-annot -c "$PWD/wrapper.ml"
  $ cat > bridge.ml <<'EOF'
  > module Alias = Wrapper
  > EOF
  $ ocamlc -w -a -bin-annot -c "$PWD/bridge.ml"
  $ cat > use.ml <<'EOF'
  > let () = Wrapper.saved ()
  > let () = ignore (Wrapper.Used : Wrapper.t); ignore (Bridge.Alias.Used : Wrapper.t)
  > EOF
  $ ocamlc -w -a -bin-annot -c "$PWD/use.ml"
  $ reanalyze.exe -ci -debug -native-build-target . -dce-cmt . > analysis.out 2>/dev/null
  $ grep -m1 -oF -- 'Live Exception +source.Used:' analysis.out
  Live Exception +source.Used:
  $ grep -m1 -oF -- 'Dead Exception +source.Used:' analysis.out
  [1]
  $ grep -m1 -oF -- 'Dead Exception +source.Unused:' analysis.out
  Dead Exception +source.Unused:
  $ grep -m1 -oF -- 'Live Exception +source.Unused:' analysis.out
  [1]

Case false-true-true-include.

  $ mkdir -p ../false-true-true-include
  $ cd "$ROOT/extension-shadow/false-true-true-include"
  $ cat > source.ml <<'EOF'
  > exception Used = Not_found
  > exception Unused = Not_found
  > EOF
  $ ocamlc -w -a -bin-annot -c "$PWD/source.ml"
  $ cat > ext.ml <<'EOF'
  > type t = ..
  > type t += Used | Other
  > EOF
  $ ocamlc -w -a -bin-annot -c "$PWD/ext.ml"
  $ cat > wrapper.ml <<'EOF'
  > include (Source : sig exception Used exception Unused end)
  > let saved () = raise Used
  > include Ext
  > EOF
  $ ocamlc -w -a -bin-annot -c "$PWD/wrapper.ml"
  $ cat > bridge.ml <<'EOF'
  > module Alias = Wrapper
  > EOF
  $ ocamlc -w -a -bin-annot -c "$PWD/bridge.ml"
  $ cat > use.ml <<'EOF'
  > let () = Wrapper.saved ()
  > let () = ignore (Wrapper.Used : Wrapper.t); ignore (Bridge.Alias.Used : Wrapper.t)
  > EOF
  $ ocamlc -w -a -bin-annot -c "$PWD/use.ml"
  $ reanalyze.exe -ci -debug -native-build-target . -dce-cmt . > analysis.out 2>/dev/null
  $ grep -m1 -oF -- 'Live Exception +source.Used:' analysis.out
  Live Exception +source.Used:
  $ grep -m1 -oF -- 'Dead Exception +source.Used:' analysis.out
  [1]
  $ grep -m1 -oF -- 'Dead Exception +source.Unused:' analysis.out
  Dead Exception +source.Unused:
  $ grep -m1 -oF -- 'Live Exception +source.Unused:' analysis.out
  [1]

Case false-true-true-rebind.

  $ mkdir -p ../false-true-true-rebind
  $ cd "$ROOT/extension-shadow/false-true-true-rebind"
  $ cat > source.ml <<'EOF'
  > exception Used = Not_found
  > exception Unused = Not_found
  > EOF
  $ ocamlc -w -a -bin-annot -c "$PWD/source.ml"
  $ cat > ext.ml <<'EOF'
  > type t = ..
  > type t += Used | Other
  > EOF
  $ ocamlc -w -a -bin-annot -c "$PWD/ext.ml"
  $ cat > wrapper.ml <<'EOF'
  > include (Source : sig exception Used exception Unused end)
  > let saved () = raise Used
  > type Ext.t += Used = Ext.Other
  > EOF
  $ ocamlc -w -a -bin-annot -c "$PWD/wrapper.ml"
  $ cat > bridge.ml <<'EOF'
  > module Alias = Wrapper
  > EOF
  $ ocamlc -w -a -bin-annot -c "$PWD/bridge.ml"
  $ cat > use.ml <<'EOF'
  > let () = Wrapper.saved ()
  > let () = ignore (Wrapper.Used : Ext.t); ignore (Bridge.Alias.Used : Ext.t)
  > EOF
  $ ocamlc -w -a -bin-annot -c "$PWD/use.ml"
  $ reanalyze.exe -ci -debug -native-build-target . -dce-cmt . > analysis.out 2>/dev/null
  $ grep -m1 -oF -- 'Live Exception +source.Used:' analysis.out
  Live Exception +source.Used:
  $ grep -m1 -oF -- 'Dead Exception +source.Used:' analysis.out
  [1]
  $ grep -m1 -oF -- 'Dead Exception +source.Unused:' analysis.out
  Dead Exception +source.Unused:
  $ grep -m1 -oF -- 'Live Exception +source.Unused:' analysis.out
  [1]

Case false-true-true-constrained-include.

  $ mkdir -p ../false-true-true-constrained-include
  $ cd "$ROOT/extension-shadow/false-true-true-constrained-include"
  $ cat > source.ml <<'EOF'
  > exception Used = Not_found
  > exception Unused = Not_found
  > EOF
  $ ocamlc -w -a -bin-annot -c "$PWD/source.ml"
  $ cat > ext.ml <<'EOF'
  > type t = ..
  > type t += Used | Other
  > EOF
  $ ocamlc -w -a -bin-annot -c "$PWD/ext.ml"
  $ cat > wrapper.ml <<'EOF'
  > include (Source : sig exception Used exception Unused end)
  > let saved () = raise Used
  > include (Ext : sig type t = .. type t += Used end)
  > EOF
  $ ocamlc -w -a -bin-annot -c "$PWD/wrapper.ml"
  $ cat > bridge.ml <<'EOF'
  > module Alias = Wrapper
  > EOF
  $ ocamlc -w -a -bin-annot -c "$PWD/bridge.ml"
  $ cat > use.ml <<'EOF'
  > let () = Wrapper.saved ()
  > let () = ignore (Wrapper.Used : Wrapper.t); ignore (Bridge.Alias.Used : Wrapper.t)
  > EOF
  $ ocamlc -w -a -bin-annot -c "$PWD/use.ml"
  $ reanalyze.exe -ci -debug -native-build-target . -dce-cmt . > analysis.out 2>/dev/null
  $ grep -m1 -oF -- 'Live Exception +source.Used:' analysis.out
  Live Exception +source.Used:
  $ grep -m1 -oF -- 'Dead Exception +source.Used:' analysis.out
  [1]
  $ grep -m1 -oF -- 'Dead Exception +source.Unused:' analysis.out
  Dead Exception +source.Unused:
  $ grep -m1 -oF -- 'Live Exception +source.Unused:' analysis.out
  [1]

Case true-false-false-direct.

  $ mkdir -p ../true-false-false-direct
  $ cd "$ROOT/extension-shadow/true-false-false-direct"
  $ cat > source.ml <<'EOF'
  > exception Used = Not_found
  > exception Unused = Not_found
  > EOF
  $ ocamlc -w -a -bin-annot -c "$PWD/source.ml"
  $ cat > ext.ml <<'EOF'
  > type exn += Used | Other
  > EOF
  $ ocamlc -w -a -bin-annot -c "$PWD/ext.ml"
  $ cat > wrapper.ml <<'EOF'
  > include Source
  > type exn += Used | Other
  > EOF
  $ ocamlc -w -a -bin-annot -c "$PWD/wrapper.ml"
  $ cat > bridge.ml <<'EOF'
  > module Alias = Wrapper
  > EOF
  $ ocamlc -w -a -bin-annot -c "$PWD/bridge.ml"
  $ cat > use.ml <<'EOF'
  > let () = ignore (Wrapper.Used : exn); ignore (Bridge.Alias.Used : exn)
  > EOF
  $ ocamlc -w -a -bin-annot -c "$PWD/use.ml"
  $ reanalyze.exe -ci -debug -native-build-target . -dce-cmt . > analysis.out 2>/dev/null
  $ grep -m1 -oF -- 'Dead Exception +source.Used:' analysis.out
  Dead Exception +source.Used:
  $ grep -m1 -oF -- 'Live Exception +source.Used:' analysis.out
  [1]
  $ grep -m1 -oF -- 'Dead Exception +source.Unused:' analysis.out
  Dead Exception +source.Unused:
  $ grep -m1 -oF -- 'Live Exception +source.Unused:' analysis.out
  [1]

Case true-false-false-include.

  $ mkdir -p ../true-false-false-include
  $ cd "$ROOT/extension-shadow/true-false-false-include"
  $ cat > source.ml <<'EOF'
  > exception Used = Not_found
  > exception Unused = Not_found
  > EOF
  $ ocamlc -w -a -bin-annot -c "$PWD/source.ml"
  $ cat > ext.ml <<'EOF'
  > type exn += Used | Other
  > EOF
  $ ocamlc -w -a -bin-annot -c "$PWD/ext.ml"
  $ cat > wrapper.ml <<'EOF'
  > include Source
  > include Ext
  > EOF
  $ ocamlc -w -a -bin-annot -c "$PWD/wrapper.ml"
  $ cat > bridge.ml <<'EOF'
  > module Alias = Wrapper
  > EOF
  $ ocamlc -w -a -bin-annot -c "$PWD/bridge.ml"
  $ cat > use.ml <<'EOF'
  > let () = ignore (Wrapper.Used : exn); ignore (Bridge.Alias.Used : exn)
  > EOF
  $ ocamlc -w -a -bin-annot -c "$PWD/use.ml"
  $ reanalyze.exe -ci -debug -native-build-target . -dce-cmt . > analysis.out 2>/dev/null
  $ grep -m1 -oF -- 'Dead Exception +source.Used:' analysis.out
  Dead Exception +source.Used:
  $ grep -m1 -oF -- 'Live Exception +source.Used:' analysis.out
  [1]
  $ grep -m1 -oF -- 'Dead Exception +source.Unused:' analysis.out
  Dead Exception +source.Unused:
  $ grep -m1 -oF -- 'Live Exception +source.Unused:' analysis.out
  [1]

Case true-false-false-rebind.

  $ mkdir -p ../true-false-false-rebind
  $ cd "$ROOT/extension-shadow/true-false-false-rebind"
  $ cat > source.ml <<'EOF'
  > exception Used = Not_found
  > exception Unused = Not_found
  > EOF
  $ ocamlc -w -a -bin-annot -c "$PWD/source.ml"
  $ cat > ext.ml <<'EOF'
  > type exn += Used | Other
  > EOF
  $ ocamlc -w -a -bin-annot -c "$PWD/ext.ml"
  $ cat > wrapper.ml <<'EOF'
  > include Source
  > type exn += Used = Ext.Other
  > EOF
  $ ocamlc -w -a -bin-annot -c "$PWD/wrapper.ml"
  $ cat > bridge.ml <<'EOF'
  > module Alias = Wrapper
  > EOF
  $ ocamlc -w -a -bin-annot -c "$PWD/bridge.ml"
  $ cat > use.ml <<'EOF'
  > let () = ignore (Wrapper.Used : exn); ignore (Bridge.Alias.Used : exn)
  > EOF
  $ ocamlc -w -a -bin-annot -c "$PWD/use.ml"
  $ reanalyze.exe -ci -debug -native-build-target . -dce-cmt . > analysis.out 2>/dev/null
  $ grep -m1 -oF -- 'Dead Exception +source.Used:' analysis.out
  Dead Exception +source.Used:
  $ grep -m1 -oF -- 'Live Exception +source.Used:' analysis.out
  [1]
  $ grep -m1 -oF -- 'Dead Exception +source.Unused:' analysis.out
  Dead Exception +source.Unused:
  $ grep -m1 -oF -- 'Live Exception +source.Unused:' analysis.out
  [1]

Case true-false-false-constrained-include.

  $ mkdir -p ../true-false-false-constrained-include
  $ cd "$ROOT/extension-shadow/true-false-false-constrained-include"
  $ cat > source.ml <<'EOF'
  > exception Used = Not_found
  > exception Unused = Not_found
  > EOF
  $ ocamlc -w -a -bin-annot -c "$PWD/source.ml"
  $ cat > ext.ml <<'EOF'
  > type exn += Used | Other
  > EOF
  $ ocamlc -w -a -bin-annot -c "$PWD/ext.ml"
  $ cat > wrapper.ml <<'EOF'
  > include Source
  > include (Ext : sig exception Used end)
  > EOF
  $ ocamlc -w -a -bin-annot -c "$PWD/wrapper.ml"
  $ cat > bridge.ml <<'EOF'
  > module Alias = Wrapper
  > EOF
  $ ocamlc -w -a -bin-annot -c "$PWD/bridge.ml"
  $ cat > use.ml <<'EOF'
  > let () = ignore (Wrapper.Used : exn); ignore (Bridge.Alias.Used : exn)
  > EOF
  $ ocamlc -w -a -bin-annot -c "$PWD/use.ml"
  $ reanalyze.exe -ci -debug -native-build-target . -dce-cmt . > analysis.out 2>/dev/null
  $ grep -m1 -oF -- 'Dead Exception +source.Used:' analysis.out
  Dead Exception +source.Used:
  $ grep -m1 -oF -- 'Live Exception +source.Used:' analysis.out
  [1]
  $ grep -m1 -oF -- 'Dead Exception +source.Unused:' analysis.out
  Dead Exception +source.Unused:
  $ grep -m1 -oF -- 'Live Exception +source.Unused:' analysis.out
  [1]

Case true-false-true-direct.

  $ mkdir -p ../true-false-true-direct
  $ cd "$ROOT/extension-shadow/true-false-true-direct"
  $ cat > source.ml <<'EOF'
  > exception Used = Not_found
  > exception Unused = Not_found
  > EOF
  $ ocamlc -w -a -bin-annot -c "$PWD/source.ml"
  $ cat > ext.ml <<'EOF'
  > type exn += Used | Other
  > EOF
  $ ocamlc -w -a -bin-annot -c "$PWD/ext.ml"
  $ cat > wrapper.ml <<'EOF'
  > include Source
  > let saved () = raise Used
  > type exn += Used | Other
  > EOF
  $ ocamlc -w -a -bin-annot -c "$PWD/wrapper.ml"
  $ cat > bridge.ml <<'EOF'
  > module Alias = Wrapper
  > EOF
  $ ocamlc -w -a -bin-annot -c "$PWD/bridge.ml"
  $ cat > use.ml <<'EOF'
  > let () = Wrapper.saved ()
  > let () = ignore (Wrapper.Used : exn); ignore (Bridge.Alias.Used : exn)
  > EOF
  $ ocamlc -w -a -bin-annot -c "$PWD/use.ml"
  $ reanalyze.exe -ci -debug -native-build-target . -dce-cmt . > analysis.out 2>/dev/null
  $ grep -m1 -oF -- 'Live Exception +source.Used:' analysis.out
  Live Exception +source.Used:
  $ grep -m1 -oF -- 'Dead Exception +source.Used:' analysis.out
  [1]
  $ grep -m1 -oF -- 'Dead Exception +source.Unused:' analysis.out
  Dead Exception +source.Unused:
  $ grep -m1 -oF -- 'Live Exception +source.Unused:' analysis.out
  [1]

Case true-false-true-include.

  $ mkdir -p ../true-false-true-include
  $ cd "$ROOT/extension-shadow/true-false-true-include"
  $ cat > source.ml <<'EOF'
  > exception Used = Not_found
  > exception Unused = Not_found
  > EOF
  $ ocamlc -w -a -bin-annot -c "$PWD/source.ml"
  $ cat > ext.ml <<'EOF'
  > type exn += Used | Other
  > EOF
  $ ocamlc -w -a -bin-annot -c "$PWD/ext.ml"
  $ cat > wrapper.ml <<'EOF'
  > include Source
  > let saved () = raise Used
  > include Ext
  > EOF
  $ ocamlc -w -a -bin-annot -c "$PWD/wrapper.ml"
  $ cat > bridge.ml <<'EOF'
  > module Alias = Wrapper
  > EOF
  $ ocamlc -w -a -bin-annot -c "$PWD/bridge.ml"
  $ cat > use.ml <<'EOF'
  > let () = Wrapper.saved ()
  > let () = ignore (Wrapper.Used : exn); ignore (Bridge.Alias.Used : exn)
  > EOF
  $ ocamlc -w -a -bin-annot -c "$PWD/use.ml"
  $ reanalyze.exe -ci -debug -native-build-target . -dce-cmt . > analysis.out 2>/dev/null
  $ grep -m1 -oF -- 'Live Exception +source.Used:' analysis.out
  Live Exception +source.Used:
  $ grep -m1 -oF -- 'Dead Exception +source.Used:' analysis.out
  [1]
  $ grep -m1 -oF -- 'Dead Exception +source.Unused:' analysis.out
  Dead Exception +source.Unused:
  $ grep -m1 -oF -- 'Live Exception +source.Unused:' analysis.out
  [1]

Case true-false-true-rebind.

  $ mkdir -p ../true-false-true-rebind
  $ cd "$ROOT/extension-shadow/true-false-true-rebind"
  $ cat > source.ml <<'EOF'
  > exception Used = Not_found
  > exception Unused = Not_found
  > EOF
  $ ocamlc -w -a -bin-annot -c "$PWD/source.ml"
  $ cat > ext.ml <<'EOF'
  > type exn += Used | Other
  > EOF
  $ ocamlc -w -a -bin-annot -c "$PWD/ext.ml"
  $ cat > wrapper.ml <<'EOF'
  > include Source
  > let saved () = raise Used
  > type exn += Used = Ext.Other
  > EOF
  $ ocamlc -w -a -bin-annot -c "$PWD/wrapper.ml"
  $ cat > bridge.ml <<'EOF'
  > module Alias = Wrapper
  > EOF
  $ ocamlc -w -a -bin-annot -c "$PWD/bridge.ml"
  $ cat > use.ml <<'EOF'
  > let () = Wrapper.saved ()
  > let () = ignore (Wrapper.Used : exn); ignore (Bridge.Alias.Used : exn)
  > EOF
  $ ocamlc -w -a -bin-annot -c "$PWD/use.ml"
  $ reanalyze.exe -ci -debug -native-build-target . -dce-cmt . > analysis.out 2>/dev/null
  $ grep -m1 -oF -- 'Live Exception +source.Used:' analysis.out
  Live Exception +source.Used:
  $ grep -m1 -oF -- 'Dead Exception +source.Used:' analysis.out
  [1]
  $ grep -m1 -oF -- 'Dead Exception +source.Unused:' analysis.out
  Dead Exception +source.Unused:
  $ grep -m1 -oF -- 'Live Exception +source.Unused:' analysis.out
  [1]

Case true-false-true-constrained-include.

  $ mkdir -p ../true-false-true-constrained-include
  $ cd "$ROOT/extension-shadow/true-false-true-constrained-include"
  $ cat > source.ml <<'EOF'
  > exception Used = Not_found
  > exception Unused = Not_found
  > EOF
  $ ocamlc -w -a -bin-annot -c "$PWD/source.ml"
  $ cat > ext.ml <<'EOF'
  > type exn += Used | Other
  > EOF
  $ ocamlc -w -a -bin-annot -c "$PWD/ext.ml"
  $ cat > wrapper.ml <<'EOF'
  > include Source
  > let saved () = raise Used
  > include (Ext : sig exception Used end)
  > EOF
  $ ocamlc -w -a -bin-annot -c "$PWD/wrapper.ml"
  $ cat > bridge.ml <<'EOF'
  > module Alias = Wrapper
  > EOF
  $ ocamlc -w -a -bin-annot -c "$PWD/bridge.ml"
  $ cat > use.ml <<'EOF'
  > let () = Wrapper.saved ()
  > let () = ignore (Wrapper.Used : exn); ignore (Bridge.Alias.Used : exn)
  > EOF
  $ ocamlc -w -a -bin-annot -c "$PWD/use.ml"
  $ reanalyze.exe -ci -debug -native-build-target . -dce-cmt . > analysis.out 2>/dev/null
  $ grep -m1 -oF -- 'Live Exception +source.Used:' analysis.out
  Live Exception +source.Used:
  $ grep -m1 -oF -- 'Dead Exception +source.Used:' analysis.out
  [1]
  $ grep -m1 -oF -- 'Dead Exception +source.Unused:' analysis.out
  Dead Exception +source.Unused:
  $ grep -m1 -oF -- 'Live Exception +source.Unused:' analysis.out
  [1]

Case true-true-false-direct.

  $ mkdir -p ../true-true-false-direct
  $ cd "$ROOT/extension-shadow/true-true-false-direct"
  $ cat > source.ml <<'EOF'
  > exception Used = Not_found
  > exception Unused = Not_found
  > EOF
  $ ocamlc -w -a -bin-annot -c "$PWD/source.ml"
  $ cat > ext.ml <<'EOF'
  > type exn += Used | Other
  > EOF
  $ ocamlc -w -a -bin-annot -c "$PWD/ext.ml"
  $ cat > wrapper.ml <<'EOF'
  > include (Source : sig exception Used exception Unused end)
  > type exn += Used | Other
  > EOF
  $ ocamlc -w -a -bin-annot -c "$PWD/wrapper.ml"
  $ cat > bridge.ml <<'EOF'
  > module Alias = Wrapper
  > EOF
  $ ocamlc -w -a -bin-annot -c "$PWD/bridge.ml"
  $ cat > use.ml <<'EOF'
  > let () = ignore (Wrapper.Used : exn); ignore (Bridge.Alias.Used : exn)
  > EOF
  $ ocamlc -w -a -bin-annot -c "$PWD/use.ml"
  $ reanalyze.exe -ci -debug -native-build-target . -dce-cmt . > analysis.out 2>/dev/null
  $ grep -m1 -oF -- 'Dead Exception +source.Used:' analysis.out
  Dead Exception +source.Used:
  $ grep -m1 -oF -- 'Live Exception +source.Used:' analysis.out
  [1]
  $ grep -m1 -oF -- 'Dead Exception +source.Unused:' analysis.out
  Dead Exception +source.Unused:
  $ grep -m1 -oF -- 'Live Exception +source.Unused:' analysis.out
  [1]

Case true-true-false-include.

  $ mkdir -p ../true-true-false-include
  $ cd "$ROOT/extension-shadow/true-true-false-include"
  $ cat > source.ml <<'EOF'
  > exception Used = Not_found
  > exception Unused = Not_found
  > EOF
  $ ocamlc -w -a -bin-annot -c "$PWD/source.ml"
  $ cat > ext.ml <<'EOF'
  > type exn += Used | Other
  > EOF
  $ ocamlc -w -a -bin-annot -c "$PWD/ext.ml"
  $ cat > wrapper.ml <<'EOF'
  > include (Source : sig exception Used exception Unused end)
  > include Ext
  > EOF
  $ ocamlc -w -a -bin-annot -c "$PWD/wrapper.ml"
  $ cat > bridge.ml <<'EOF'
  > module Alias = Wrapper
  > EOF
  $ ocamlc -w -a -bin-annot -c "$PWD/bridge.ml"
  $ cat > use.ml <<'EOF'
  > let () = ignore (Wrapper.Used : exn); ignore (Bridge.Alias.Used : exn)
  > EOF
  $ ocamlc -w -a -bin-annot -c "$PWD/use.ml"
  $ reanalyze.exe -ci -debug -native-build-target . -dce-cmt . > analysis.out 2>/dev/null
  $ grep -m1 -oF -- 'Dead Exception +source.Used:' analysis.out
  Dead Exception +source.Used:
  $ grep -m1 -oF -- 'Live Exception +source.Used:' analysis.out
  [1]
  $ grep -m1 -oF -- 'Dead Exception +source.Unused:' analysis.out
  Dead Exception +source.Unused:
  $ grep -m1 -oF -- 'Live Exception +source.Unused:' analysis.out
  [1]

Case true-true-false-rebind.

  $ mkdir -p ../true-true-false-rebind
  $ cd "$ROOT/extension-shadow/true-true-false-rebind"
  $ cat > source.ml <<'EOF'
  > exception Used = Not_found
  > exception Unused = Not_found
  > EOF
  $ ocamlc -w -a -bin-annot -c "$PWD/source.ml"
  $ cat > ext.ml <<'EOF'
  > type exn += Used | Other
  > EOF
  $ ocamlc -w -a -bin-annot -c "$PWD/ext.ml"
  $ cat > wrapper.ml <<'EOF'
  > include (Source : sig exception Used exception Unused end)
  > type exn += Used = Ext.Other
  > EOF
  $ ocamlc -w -a -bin-annot -c "$PWD/wrapper.ml"
  $ cat > bridge.ml <<'EOF'
  > module Alias = Wrapper
  > EOF
  $ ocamlc -w -a -bin-annot -c "$PWD/bridge.ml"
  $ cat > use.ml <<'EOF'
  > let () = ignore (Wrapper.Used : exn); ignore (Bridge.Alias.Used : exn)
  > EOF
  $ ocamlc -w -a -bin-annot -c "$PWD/use.ml"
  $ reanalyze.exe -ci -debug -native-build-target . -dce-cmt . > analysis.out 2>/dev/null
  $ grep -m1 -oF -- 'Dead Exception +source.Used:' analysis.out
  Dead Exception +source.Used:
  $ grep -m1 -oF -- 'Live Exception +source.Used:' analysis.out
  [1]
  $ grep -m1 -oF -- 'Dead Exception +source.Unused:' analysis.out
  Dead Exception +source.Unused:
  $ grep -m1 -oF -- 'Live Exception +source.Unused:' analysis.out
  [1]

Case true-true-false-constrained-include.

  $ mkdir -p ../true-true-false-constrained-include
  $ cd "$ROOT/extension-shadow/true-true-false-constrained-include"
  $ cat > source.ml <<'EOF'
  > exception Used = Not_found
  > exception Unused = Not_found
  > EOF
  $ ocamlc -w -a -bin-annot -c "$PWD/source.ml"
  $ cat > ext.ml <<'EOF'
  > type exn += Used | Other
  > EOF
  $ ocamlc -w -a -bin-annot -c "$PWD/ext.ml"
  $ cat > wrapper.ml <<'EOF'
  > include (Source : sig exception Used exception Unused end)
  > include (Ext : sig exception Used end)
  > EOF
  $ ocamlc -w -a -bin-annot -c "$PWD/wrapper.ml"
  $ cat > bridge.ml <<'EOF'
  > module Alias = Wrapper
  > EOF
  $ ocamlc -w -a -bin-annot -c "$PWD/bridge.ml"
  $ cat > use.ml <<'EOF'
  > let () = ignore (Wrapper.Used : exn); ignore (Bridge.Alias.Used : exn)
  > EOF
  $ ocamlc -w -a -bin-annot -c "$PWD/use.ml"
  $ reanalyze.exe -ci -debug -native-build-target . -dce-cmt . > analysis.out 2>/dev/null
  $ grep -m1 -oF -- 'Dead Exception +source.Used:' analysis.out
  Dead Exception +source.Used:
  $ grep -m1 -oF -- 'Live Exception +source.Used:' analysis.out
  [1]
  $ grep -m1 -oF -- 'Dead Exception +source.Unused:' analysis.out
  Dead Exception +source.Unused:
  $ grep -m1 -oF -- 'Live Exception +source.Unused:' analysis.out
  [1]

Case true-true-true-direct.

  $ mkdir -p ../true-true-true-direct
  $ cd "$ROOT/extension-shadow/true-true-true-direct"
  $ cat > source.ml <<'EOF'
  > exception Used = Not_found
  > exception Unused = Not_found
  > EOF
  $ ocamlc -w -a -bin-annot -c "$PWD/source.ml"
  $ cat > ext.ml <<'EOF'
  > type exn += Used | Other
  > EOF
  $ ocamlc -w -a -bin-annot -c "$PWD/ext.ml"
  $ cat > wrapper.ml <<'EOF'
  > include (Source : sig exception Used exception Unused end)
  > let saved () = raise Used
  > type exn += Used | Other
  > EOF
  $ ocamlc -w -a -bin-annot -c "$PWD/wrapper.ml"
  $ cat > bridge.ml <<'EOF'
  > module Alias = Wrapper
  > EOF
  $ ocamlc -w -a -bin-annot -c "$PWD/bridge.ml"
  $ cat > use.ml <<'EOF'
  > let () = Wrapper.saved ()
  > let () = ignore (Wrapper.Used : exn); ignore (Bridge.Alias.Used : exn)
  > EOF
  $ ocamlc -w -a -bin-annot -c "$PWD/use.ml"
  $ reanalyze.exe -ci -debug -native-build-target . -dce-cmt . > analysis.out 2>/dev/null
  $ grep -m1 -oF -- 'Live Exception +source.Used:' analysis.out
  Live Exception +source.Used:
  $ grep -m1 -oF -- 'Dead Exception +source.Used:' analysis.out
  [1]
  $ grep -m1 -oF -- 'Dead Exception +source.Unused:' analysis.out
  Dead Exception +source.Unused:
  $ grep -m1 -oF -- 'Live Exception +source.Unused:' analysis.out
  [1]

Case true-true-true-include.

  $ mkdir -p ../true-true-true-include
  $ cd "$ROOT/extension-shadow/true-true-true-include"
  $ cat > source.ml <<'EOF'
  > exception Used = Not_found
  > exception Unused = Not_found
  > EOF
  $ ocamlc -w -a -bin-annot -c "$PWD/source.ml"
  $ cat > ext.ml <<'EOF'
  > type exn += Used | Other
  > EOF
  $ ocamlc -w -a -bin-annot -c "$PWD/ext.ml"
  $ cat > wrapper.ml <<'EOF'
  > include (Source : sig exception Used exception Unused end)
  > let saved () = raise Used
  > include Ext
  > EOF
  $ ocamlc -w -a -bin-annot -c "$PWD/wrapper.ml"
  $ cat > bridge.ml <<'EOF'
  > module Alias = Wrapper
  > EOF
  $ ocamlc -w -a -bin-annot -c "$PWD/bridge.ml"
  $ cat > use.ml <<'EOF'
  > let () = Wrapper.saved ()
  > let () = ignore (Wrapper.Used : exn); ignore (Bridge.Alias.Used : exn)
  > EOF
  $ ocamlc -w -a -bin-annot -c "$PWD/use.ml"
  $ reanalyze.exe -ci -debug -native-build-target . -dce-cmt . > analysis.out 2>/dev/null
  $ grep -m1 -oF -- 'Live Exception +source.Used:' analysis.out
  Live Exception +source.Used:
  $ grep -m1 -oF -- 'Dead Exception +source.Used:' analysis.out
  [1]
  $ grep -m1 -oF -- 'Dead Exception +source.Unused:' analysis.out
  Dead Exception +source.Unused:
  $ grep -m1 -oF -- 'Live Exception +source.Unused:' analysis.out
  [1]

Case true-true-true-rebind.

  $ mkdir -p ../true-true-true-rebind
  $ cd "$ROOT/extension-shadow/true-true-true-rebind"
  $ cat > source.ml <<'EOF'
  > exception Used = Not_found
  > exception Unused = Not_found
  > EOF
  $ ocamlc -w -a -bin-annot -c "$PWD/source.ml"
  $ cat > ext.ml <<'EOF'
  > type exn += Used | Other
  > EOF
  $ ocamlc -w -a -bin-annot -c "$PWD/ext.ml"
  $ cat > wrapper.ml <<'EOF'
  > include (Source : sig exception Used exception Unused end)
  > let saved () = raise Used
  > type exn += Used = Ext.Other
  > EOF
  $ ocamlc -w -a -bin-annot -c "$PWD/wrapper.ml"
  $ cat > bridge.ml <<'EOF'
  > module Alias = Wrapper
  > EOF
  $ ocamlc -w -a -bin-annot -c "$PWD/bridge.ml"
  $ cat > use.ml <<'EOF'
  > let () = Wrapper.saved ()
  > let () = ignore (Wrapper.Used : exn); ignore (Bridge.Alias.Used : exn)
  > EOF
  $ ocamlc -w -a -bin-annot -c "$PWD/use.ml"
  $ reanalyze.exe -ci -debug -native-build-target . -dce-cmt . > analysis.out 2>/dev/null
  $ grep -m1 -oF -- 'Live Exception +source.Used:' analysis.out
  Live Exception +source.Used:
  $ grep -m1 -oF -- 'Dead Exception +source.Used:' analysis.out
  [1]
  $ grep -m1 -oF -- 'Dead Exception +source.Unused:' analysis.out
  Dead Exception +source.Unused:
  $ grep -m1 -oF -- 'Live Exception +source.Unused:' analysis.out
  [1]

Case true-true-true-constrained-include.

  $ mkdir -p ../true-true-true-constrained-include
  $ cd "$ROOT/extension-shadow/true-true-true-constrained-include"
  $ cat > source.ml <<'EOF'
  > exception Used = Not_found
  > exception Unused = Not_found
  > EOF
  $ ocamlc -w -a -bin-annot -c "$PWD/source.ml"
  $ cat > ext.ml <<'EOF'
  > type exn += Used | Other
  > EOF
  $ ocamlc -w -a -bin-annot -c "$PWD/ext.ml"
  $ cat > wrapper.ml <<'EOF'
  > include (Source : sig exception Used exception Unused end)
  > let saved () = raise Used
  > include (Ext : sig exception Used end)
  > EOF
  $ ocamlc -w -a -bin-annot -c "$PWD/wrapper.ml"
  $ cat > bridge.ml <<'EOF'
  > module Alias = Wrapper
  > EOF
  $ ocamlc -w -a -bin-annot -c "$PWD/bridge.ml"
  $ cat > use.ml <<'EOF'
  > let () = Wrapper.saved ()
  > let () = ignore (Wrapper.Used : exn); ignore (Bridge.Alias.Used : exn)
  > EOF
  $ ocamlc -w -a -bin-annot -c "$PWD/use.ml"
  $ reanalyze.exe -ci -debug -native-build-target . -dce-cmt . > analysis.out 2>/dev/null
  $ grep -m1 -oF -- 'Live Exception +source.Used:' analysis.out
  Live Exception +source.Used:
  $ grep -m1 -oF -- 'Dead Exception +source.Used:' analysis.out
  [1]
  $ grep -m1 -oF -- 'Dead Exception +source.Unused:' analysis.out
  Dead Exception +source.Unused:
  $ grep -m1 -oF -- 'Live Exception +source.Unused:' analysis.out
  [1]
