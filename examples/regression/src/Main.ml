let definitely_dead () = ()

let () =
  Live_ancestors.use_child ();
  Functor_argument.use_set ();
  Functor_argument.use_anonymous_set ();
  Local_side_effects.start ();
  Ocaml_compiler_compat.run ();
  Shared_signature_use.run ();
  Shared_signature_arg.run ();
  Shared_signature_arg.run_more ()
