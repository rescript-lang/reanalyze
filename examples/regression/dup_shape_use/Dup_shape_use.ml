(* The consumer has no sibling Dup_shape: the importer digest must choose
   dup_a and retain its implementation shape as well as its interface. *)
let () = ignore (Dup_shape.A_chosen.f 1)
