Compile the same source as bytecode and native code, as Dune does: the
native compilation reuses the bytecode .cmi and records no interface digest.

  $ SOURCE=$(cd ../examples/regression/duplicate_native && pwd)/Duplicate_native.ml
  $ mkdir byte native
  $ ocamlc -bin-annot -c -o byte/Duplicate_native.cmo "$SOURCE"
  $ ocamlopt -bin-annot -intf-suffix .ml -I byte -c -o native/Duplicate_native.cmx "$SOURCE"

Scanning byte and native artifacts must not change optional-call counts.

  $ reanalyze.exe -ci -dce-cmt byte > byte.out 2>/dev/null
  $ grep -m1 -oF -- 'optional argument x of function +g is always supplied (1 calls)' byte.out
  optional argument x of function +g is always supplied (1 calls)
  $ reanalyze.exe -ci -dce-cmt . > all.out 2>/dev/null
  $ cmp byte.out all.out
