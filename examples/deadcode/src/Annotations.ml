let[@live] live_value () = ()

let[@dead] intentionally_dead () = ()

let stale_dead_annotation () = ()

(* genType is a ReScript annotation; in OCaml it does not keep a value live. *)
let[@genType] gentype_annotated () = ()
