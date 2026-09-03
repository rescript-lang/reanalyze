let definitely_dead () = ()

let () =
  Live_ancestors.use_child ();
  Functor_argument.use_set ();
  Functor_argument.use_anonymous_set ();
  Local_side_effects.start ();
  Ocaml_compiler_compat.run ();
  Shared_signature_use.run ();
  Shared_signature_arg.run ();
  Shared_signature_arg.run_more ();
  Shared_signature_arg.run_even_more ();
  Shared_signature_arg.run_sig ();
  Shared_signature_arg.run_partial ();
  Shared_signature_arg.run_alias ();
  Shared_signature_arg.run_forwarded ();
  Nested_module_type.run ();
  Shared_signature_arg.run_shadow ();
  Shared_signature_arg.run_nested ();
  Shared_signature_arg.run_chain ();
  Cross_alias_use.run ();
  Cross_alias_use.run_partial ();
  Cross_alias_use.run_incl ();
  Cross_alias_use.run_y ();
  Shared_signature_arg.run_local_partial ();
  ignore (Included_sig.M.f ());
  ignore (Included_sig.W.X.f ());
  Shared_signature_arg.run_alias9 ();
  Shared_signature_arg.run_ext ();
  Shared_signature_arg.run_shadow_rec ();
  ignore (Included_sig.W2.X.f ());
  ignore (Included_sig.W3.X.f ());
  Shared_signature_arg.run_incl_f ();
  Shared_signature_arg.run_rec_chain ();
  Shared_signature_arg.run_mt ()
