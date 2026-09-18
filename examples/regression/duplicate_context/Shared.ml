(* Both builds have the same source and inferred interface, but resolve
   Provider.g against different imported interfaces. *)
let run () = ignore (Provider.g ~x:1 ())
let () = run ()
