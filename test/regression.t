Regression fixtures in examples/regression. Each grep prints a line the
analysis must report; [1] marks one it must not report.

  $ cp -r ../examples/regression . && cd regression
  $ dune build --root . 2>&1

  $ reanalyze.exe -ci -debug -native-build-target . -dce-cmt _build/default/exception_collision/.exception_collision.objs/byte > exception_collision.out 2>/dev/null
  $ reanalyze.exe -ci -debug -native-build-target . -dce-cmt _build/default/src/.regression_fixture.objs/byte > regression.out 2>/dev/null
  $ reanalyze.exe -ci -debug -native-build-target . -dce-cmt _build/default > all.out 2>/dev/null

Outer.Inner.Alias belongs to an external unit outside this analysis root.
Its real namespace must not be stripped to reference the local Inner.Alias.

  $ grep -m1 -oF -- 'Dead Exception +Inner.Alias' exception_collision.out
  Dead Exception +Inner.Alias
  $ grep -m1 -oF -- 'Live Exception +Inner.Alias' exception_collision.out
  [1]
  $ grep -m1 -oF -- '+definitely_dead is never used' regression.out
  +definitely_dead is never used

Exception aliases reached through nested module targets, including an alias chain and the surrounding Dune wrapper, stay live independently.

  $ grep -m1 -oF -- 'Live Exception +Exception_nested_source.Inner.Direct' regression.out
  Live Exception +Exception_nested_source.Inner.Direct
  $ grep -m1 -oF -- 'Dead Exception +Exception_nested_source.Inner.Direct' regression.out
  [1]
  $ grep -m1 -oF -- 'Live Exception +Exception_nested_source.Inner.Through_chain' regression.out
  Live Exception +Exception_nested_source.Inner.Through_chain
  $ grep -m1 -oF -- 'Dead Exception +Exception_nested_source.Inner.Through_chain' regression.out
  [1]
  $ grep -m1 -oF -- 'Live Exception +Exception_nested_source.Inner.Through_nested_alias' regression.out
  Live Exception +Exception_nested_source.Inner.Through_nested_alias
  $ grep -m1 -oF -- 'Dead Exception +Exception_nested_source.Inner.Through_nested_alias' regression.out
  [1]
  $ grep -m1 -oF -- 'Live Exception +Exception_nested_source.Inner.Through_include' regression.out
  Live Exception +Exception_nested_source.Inner.Through_include
  $ grep -m1 -oF -- 'Dead Exception +Exception_nested_source.Inner.Through_include' regression.out
  [1]
  $ grep -m1 -oF -- 'Live Exception +Exception_nested_source.Inner.Deep.Used' regression.out
  Live Exception +Exception_nested_source.Inner.Deep.Used
  $ grep -m1 -oF -- 'Dead Exception +Exception_nested_source.Inner.Deep.Used' regression.out
  [1]
  $ grep -m1 -oF -- 'Dead Exception +Exception_nested_source.Inner.Unused' regression.out
  Dead Exception +Exception_nested_source.Inner.Unused
  $ grep -m1 -oF -- 'Live Exception +Exception_nested_source.Inner.Unused' regression.out
  [1]
  $ grep -m1 -oF -- 'Dead Exception +Exception_nested_source.Inner.Deep.Unused' regression.out
  Dead Exception +Exception_nested_source.Inner.Deep.Unused
  $ grep -m1 -oF -- 'Live Exception +Exception_nested_source.Inner.Deep.Unused' regression.out
  [1]

Local alias roots retain their lexical module identity, including aliases inside nested signatures and references to an outer scope.

  $ grep -m1 -oF -- 'Live Exception +Exception_scoped_alias.Source.Direct' regression.out
  Live Exception +Exception_scoped_alias.Source.Direct
  $ grep -m1 -oF -- 'Dead Exception +Exception_scoped_alias.Source.Direct' regression.out
  [1]
  $ grep -m1 -oF -- 'Live Exception +Exception_scoped_alias.Source.Fresh' regression.out
  Live Exception +Exception_scoped_alias.Source.Fresh
  $ grep -m1 -oF -- 'Dead Exception +Exception_scoped_alias.Source.Fresh' regression.out
  [1]
  $ grep -m1 -oF -- 'Live Exception +Exception_scoped_alias.Source.Through_nested' regression.out
  Live Exception +Exception_scoped_alias.Source.Through_nested
  $ grep -m1 -oF -- 'Dead Exception +Exception_scoped_alias.Source.Through_nested' regression.out
  [1]
  $ grep -m1 -oF -- 'Live Exception +Exception_scoped_alias.Source.Deep.Used' regression.out
  Live Exception +Exception_scoped_alias.Source.Deep.Used
  $ grep -m1 -oF -- 'Dead Exception +Exception_scoped_alias.Source.Deep.Used' regression.out
  [1]
  $ grep -m1 -oF -- 'Live Exception +Exception_scoped_alias.Nested.Source.Shadowed' regression.out
  Live Exception +Exception_scoped_alias.Nested.Source.Shadowed
  $ grep -m1 -oF -- 'Dead Exception +Exception_scoped_alias.Nested.Source.Shadowed' regression.out
  [1]
  $ grep -m1 -oF -- 'Live Exception +Exception_scoped_alias.Nested.Source.Through_deeper' regression.out
  Live Exception +Exception_scoped_alias.Nested.Source.Through_deeper
  $ grep -m1 -oF -- 'Dead Exception +Exception_scoped_alias.Nested.Source.Through_deeper' regression.out
  [1]
  $ grep -m1 -oF -- 'Live Exception +Exception_scoped_alias.Constrained.Source.Used' regression.out
  Live Exception +Exception_scoped_alias.Constrained.Source.Used
  $ grep -m1 -oF -- 'Dead Exception +Exception_scoped_alias.Constrained.Source.Used' regression.out
  [1]
  $ grep -m1 -oF -- 'Live Exception +Exception_scoped_alias.Constrained.Source.Forwarded' regression.out
  Live Exception +Exception_scoped_alias.Constrained.Source.Forwarded
  $ grep -m1 -oF -- 'Dead Exception +Exception_scoped_alias.Constrained.Source.Forwarded' regression.out
  [1]
  $ grep -m1 -oF -- 'Dead Exception +Exception_scoped_alias.Source.Shadowed' regression.out
  Dead Exception +Exception_scoped_alias.Source.Shadowed
  $ grep -m1 -oF -- 'Live Exception +Exception_scoped_alias.Source.Shadowed' regression.out
  [1]
  $ grep -m1 -oF -- 'Dead Exception +Exception_scoped_alias.Source.Unused' regression.out
  Dead Exception +Exception_scoped_alias.Source.Unused
  $ grep -m1 -oF -- 'Live Exception +Exception_scoped_alias.Source.Unused' regression.out
  [1]
  $ grep -m1 -oF -- 'Dead Exception +Exception_scoped_alias.Source.Deep.Unused' regression.out
  Dead Exception +Exception_scoped_alias.Source.Deep.Unused
  $ grep -m1 -oF -- 'Live Exception +Exception_scoped_alias.Source.Deep.Unused' regression.out
  [1]
  $ grep -m1 -oF -- 'Dead Exception +Exception_scoped_alias.Nested.Source.Unused' regression.out
  Dead Exception +Exception_scoped_alias.Nested.Source.Unused
  $ grep -m1 -oF -- 'Live Exception +Exception_scoped_alias.Nested.Source.Unused' regression.out
  [1]
  $ grep -m1 -oF -- 'Dead Exception +Exception_scoped_alias.Constrained.Source.Unused' regression.out
  Dead Exception +Exception_scoped_alias.Constrained.Source.Unused
  $ grep -m1 -oF -- 'Live Exception +Exception_scoped_alias.Constrained.Source.Unused' regression.out
  [1]
  $ grep -m1 -oF -- 'Dead Exception +Exception_scoped_alias.Other.Source.Used' regression.out
  Dead Exception +Exception_scoped_alias.Other.Source.Used
  $ grep -m1 -oF -- 'Live Exception +Exception_scoped_alias.Other.Source.Used' regression.out
  [1]
  $ grep -m1 -oF -- 'Dead Exception +Exception_scoped_alias.Other.Source.Forwarded' regression.out
  Dead Exception +Exception_scoped_alias.Other.Source.Forwarded
  $ grep -m1 -oF -- 'Live Exception +Exception_scoped_alias.Other.Source.Forwarded' regression.out
  [1]
  $ grep -m1 -oF -- 'Dead Exception +Exception_scoped_alias.Other.Source.Unused' regression.out
  Dead Exception +Exception_scoped_alias.Other.Source.Unused
  $ grep -m1 -oF -- 'Live Exception +Exception_scoped_alias.Other.Source.Unused' regression.out
  [1]
  $ grep -m1 -oF -- 'Rec_used is never raised' regression.out
  [1]
  $ grep -m1 -oF -- 'Rec_unused is never raised' regression.out
  Rec_unused is never raised
  $ grep -m1 -oF -- 'Live Exception +Exception_alias_exports.Local.Through_local_include' regression.out
  Live Exception +Exception_alias_exports.Local.Through_local_include
  $ grep -m1 -oF -- 'Dead Exception +Exception_alias_exports.Local.Through_local_include' regression.out
  [1]
  $ grep -m1 -oF -- 'Dead Exception +Exception_alias_exports.Local.Unused' regression.out
  Dead Exception +Exception_alias_exports.Local.Unused
  $ grep -m1 -oF -- 'Live Exception +Exception_alias_exports.Local.Unused' regression.out
  [1]
  $ grep -m1 -oF -- Source:src/Generated_source.ml regression.out
  Source:src/Generated_source.ml
  $ grep -m1 -oF -- 'Live Value +Functor_argument.Ordered.+compare' regression.out
  Live Value +Functor_argument.Ordered.+compare
  $ grep -m1 -oF -- 'Dead Value +Functor_argument.Ordered.+unused' regression.out
  Dead Value +Functor_argument.Ordered.+unused
  $ grep -m1 -oF -- 'Live Value +Functor_argument.Anonymous_set.+compare' regression.out
  Live Value +Functor_argument.Anonymous_set.+compare
  $ grep -m1 -oF -- 'Dead Value +Functor_argument.Anonymous_set.+unused' regression.out
  Dead Value +Functor_argument.Anonymous_set.+unused
  $ grep -m1 -oF -- 'Live Value +Local_side_effects.+_info' regression.out
  Live Value +Local_side_effects.+_info
  $ grep -m1 -oF -- 'Live Value +Local_side_effects.+process' regression.out
  Live Value +Local_side_effects.+process
  $ grep -m1 -oF -- 'Live Value +Local_side_effects.+register' regression.out
  Live Value +Local_side_effects.+register

Values copied by a named module-type include in an .mli must resolve back to their implementations, even though they share one location.

  $ grep -m1 -oF -- 'Live Value +IncludeSigMli.+equal' regression.out
  Live Value +IncludeSigMli.+equal
  $ grep -m1 -oF -- 'Dead Value +IncludeSigMli.+equal' regression.out
  [1]

Types of a submodule of an interface keep their module path, so they are matched with their implementation.

  $ grep -m1 -oF -- 'Live VariantCase Nested_sig_type.Color.setting.Auto:' regression.out
  Live VariantCase Nested_sig_type.Color.setting.Auto:
  $ grep -m1 -oF -- 'Dead VariantCase Nested_sig_type.Color.setting.Auto:' regression.out
  [1]
  $ grep -m1 -oF -- 'Live VariantCase Nested_sig_type.Color.setting.Never:' regression.out
  Live VariantCase Nested_sig_type.Color.setting.Never:
  $ grep -m1 -oF -- 'Dead VariantCase Nested_sig_type.Color.setting.Never:' regression.out
  [1]
  $ grep -m1 -oF -- 'Live RecordLabel Nested_sig_type.Color.styles.error:' regression.out
  Live RecordLabel Nested_sig_type.Color.styles.error:
  $ grep -m1 -oF -- 'Dead RecordLabel Nested_sig_type.Color.styles.error:' regression.out
  [1]
  $ grep -m1 -oF -- 'Dead VariantCase Nested_sig_type.Color.setting.Unused_setting:' regression.out
  Dead VariantCase Nested_sig_type.Color.setting.Unused_setting:
  $ grep -m1 -oF -- 'Dead RecordLabel Nested_sig_type.Color.styles.unused_style:' regression.out
  Dead RecordLabel Nested_sig_type.Color.styles.unused_style:
  $ grep -m1 -oF -- 'Live VariantCase +Nested_sig_type.Color.setting.Auto:' regression.out
  Live VariantCase +Nested_sig_type.Color.setting.Auto:
  $ grep -m1 -oF -- 'Dead VariantCase +Nested_sig_type.Color.setting.Auto:' regression.out
  [1]
  $ grep -m1 -oF -- 'Live VariantCase +Nested_sig_type.Color.setting.Never:' regression.out
  Live VariantCase +Nested_sig_type.Color.setting.Never:
  $ grep -m1 -oF -- 'Dead VariantCase +Nested_sig_type.Color.setting.Never:' regression.out
  [1]
  $ grep -m1 -oF -- 'Live RecordLabel +Nested_sig_type.Color.styles.error:' regression.out
  Live RecordLabel +Nested_sig_type.Color.styles.error:
  $ grep -m1 -oF -- 'Dead RecordLabel +Nested_sig_type.Color.styles.error:' regression.out
  [1]
  $ grep -m1 -oF -- 'Dead VariantCase +Nested_sig_type.Color.setting.Unused_setting:' regression.out
  Dead VariantCase +Nested_sig_type.Color.setting.Unused_setting:
  $ grep -m1 -oF -- 'Dead RecordLabel +Nested_sig_type.Color.styles.unused_style:' regression.out
  Dead RecordLabel +Nested_sig_type.Color.styles.unused_style:

Aliases and partial applications of functions with optional parameters do not own them; functions defined here still do.

  $ grep -m1 -oF -- 'optional argument pp_sep of function +print_list' regression.out
  [1]
  $ grep -m1 -oF -- 'optional argument pp_sep of function +print_ints' regression.out
  [1]
  $ grep -m1 -oF -- 'optional argument unused_opt of function +local_function is never used' regression.out
  optional argument unused_opt of function +local_function is never used
  $ grep -m1 -oF -- 'optional argument through_alias of function +base is always supplied (1 calls)' regression.out
  optional argument through_alias of function +base is always supplied (1 calls)
  $ grep -m1 -oF -- 'optional argument never_through_alias of function +base_never is never used' regression.out
  optional argument never_through_alias of function +base_never is never used

An alias exported through an interface has no optional parameters of its own; calls through it are calls of the aliased function.

  $ grep -m1 -oF -- 'of function +iface_alias ' regression.out
  [1]
  $ grep -m1 -oF -- 'of function +iface_alias_never ' regression.out
  [1]
  $ grep -m1 -oF -- 'optional argument x of function +iface_target is always supplied' regression.out
  optional argument x of function +iface_target is always supplied
  $ grep -m1 -oF -- 'optional argument y of function +iface_target_never is never used' regression.out
  optional argument y of function +iface_target_never is never used

... also when it aliases a value of a module constrained by a signature.

  $ grep -m1 -oF -- 'of function +sig_alias ' regression.out
  [1]
  $ grep -m1 -oF -- 'optional argument x of function M.+sig_f is never used' regression.out
  [1]

A binding whose body is not syntactically a function still owns its optional parameters.

  $ grep -m1 -oF -- 'optional argument x of function +let_in_fun is never used' regression.out
  optional argument x of function +let_in_fun is never used
  $ grep -m1 -oF -- 'optional argument x of function +if_fun is never used' regression.out
  optional argument x of function +if_fun is never used

A binding is an alias only for the optional parameters the applied function leaves (including those a partial application skips), not for ones that merely share a name.

  $ grep -m1 -oF -- 'optional argument x of function +wrap is never used' regression.out
  optional argument x of function +wrap is never used
  $ grep -m1 -oF -- 'optional argument x of function +skipped is always supplied (1 calls)' regression.out
  optional argument x of function +skipped is always supplied (1 calls)

A binding that is not an alias owns no optional parameters, so calls through it never make one "always supplied"; the function among its arguments may receive them.

  $ grep -m1 -oF -- 'of function +wrapped_g ' regression.out
  [1]
  $ grep -m1 -oF -- 'of function +wrapped ' regression.out
  [1]
  $ grep -m1 -oF -- 'of function +via_lambda ' regression.out
  [1]
  $ grep -m1 -oF -- 'of function +lambda_applied ' regression.out
  [1]
  $ grep -m1 -oF -- 'optional argument z of function +unrelated is never used' regression.out
  optional argument z of function +unrelated is never used
  $ grep -m1 -oF -- 'of function +picked_from ' regression.out
  [1]

Calls through a partial application pass what it applies; the application itself is a call only when nobody calls through it.

  $ grep -m1 -oF -- 'optional argument x of function +partial_x is always supplied (2 calls)' regression.out
  optional argument x of function +partial_x is always supplied (2 calls)
  $ grep -m1 -oF -- 'optional argument y of function +partial_x ' regression.out
  [1]
  $ grep -m1 -oF -- 'of function +partial_xp ' regression.out
  [1]
  $ grep -m1 -oF -- 'optional argument x of function +uncalled is always supplied (1 calls)' regression.out
  optional argument x of function +uncalled is always supplied (1 calls)
  $ grep -m1 -oF -- 'optional argument x of function Sig_partial_m.+sf is always supplied (1 calls)' regression.out
  optional argument x of function Sig_partial_m.+sf is always supplied (1 calls)
  $ grep -m1 -oF -- 'optional argument x of function Sig_partial_m.+sf is never used' regression.out
  [1]
  $ grep -m1 -oF -- 'optional argument x of function +chain is always supplied (1 calls)' regression.out
  optional argument x of function +chain is always supplied (1 calls)
  $ grep -m1 -oF -- 'optional argument y of function +chain is always supplied (1 calls)' regression.out
  optional argument y of function +chain is always supplied (1 calls)
  $ grep -m1 -oF -- 'optional argument z of function +chain is never used' regression.out
  optional argument z of function +chain is never used
  $ grep -m1 -oF -- 'optional argument y of function +piped_h is always supplied (1 calls)' regression.out
  optional argument y of function +piped_h is always supplied (1 calls)
  $ grep -m1 -oF -- 'optional argument y of function +piped_h is never used' regression.out
  [1]
  $ grep -m1 -oF -- 'optional argument y of function +pipe_f is always supplied (1 calls)' regression.out
  optional argument y of function +pipe_f is always supplied (1 calls)
  $ grep -m1 -oF -- 'optional argument x of function +pipe_f is always supplied (1 calls)' regression.out
  optional argument x of function +pipe_f is always supplied (1 calls)
  $ grep -m1 -oF -- 'of function +pipe_p ' regression.out
  [1]

Labels hidden by an abbreviation: a constrained alias, and an interface naming the type of a function with optional parameters.

  $ grep -m1 -oF -- 'optional argument x of function +plain ' regression.out
  [1]
  $ grep -m1 -oF -- 'of function +plain_g ' regression.out
  [1]
  $ grep -m1 -oF -- 'optional argument x of function +abbrev is never used' regression.out
  [1]
  $ grep -m1 -oF -- 'optional argument x of function +abbrev is always supplied (1 calls)' regression.out
  optional argument x of function +abbrev is always supplied (1 calls)
  $ grep -m1 -oF -- 'optional argument x of function +abbrev_never is never used' regression.out
  optional argument x of function +abbrev_never is never used

... also through a further alias, whose type shows no labels either.

  $ grep -m1 -oF -- 'optional argument x of function +doubly is always supplied (1 calls)' regression.out
  optional argument x of function +doubly is always supplied (1 calls)
  $ grep -m1 -oF -- 'optional argument x of function +doubly is never used' regression.out
  [1]
  $ grep -m1 -oF -- 'optional argument x of function +abbrev_aliased is always supplied (1 calls)' regression.out
  optional argument x of function +abbrev_aliased is always supplied (1 calls)
  $ grep -m1 -oF -- 'optional argument x of function +abbrev_aliased is never used' regression.out
  [1]

A function passed to a parameter of a named function type keeps its optional parameters.

  $ grep -m1 -oF -- 'optional argument loc of function +named_lookup' regression.out
  [1]

Passing a function to a parameter of type 'a (ignore, ref) supplies nothing.

  $ grep -m1 -oF -- 'optional argument x of function +ignored is never used' regression.out
  optional argument x of function +ignored is never used
  $ grep -m1 -oF -- 'optional argument y of function +in_ref is never used' regression.out
  optional argument y of function +in_ref is never used

A re-export of a type outside the analysis does not make its constructors live.

  $ grep -m1 -oF -- 'Dead VariantCase +Type_reexport_stdlib.node.Cons:' regression.out
  Dead VariantCase +Type_reexport_stdlib.node.Cons:

A function passed as an argument keeps its optional parameters for the callee to supply; one only called without them is still reported.

  $ grep -m1 -oF -- 'optional argument loc of function +local_lookup' regression.out
  [1]
  $ grep -m1 -oF -- 'optional argument loc of function +lookup ' regression.out
  [1]
  $ grep -m1 -oF -- 'optional argument loc of function +never_passed is never used' regression.out
  optional argument loc of function +never_passed is never used

A call through one functor instance must never mark the used implementation dead.

  $ grep -m1 -oF -- 'Live Value +Shared_signature_used.Make.+f' regression.out
  Live Value +Shared_signature_used.Make.+f
  $ grep -m1 -oF -- 'Dead Value +Shared_signature_used.Make.+f' regression.out
  [1]
  $ grep -m1 -oF -- 'Live Value +Shared_signature_arg.Chosen.+f' regression.out
  Live Value +Shared_signature_arg.Chosen.+f
  $ grep -m1 -oF -- 'Dead Value +Shared_signature_arg.Chosen.+f' regression.out
  [1]
  $ grep -m1 -oF -- 'Live Value +Shared_signature_arg.Local_used.+f' regression.out
  Live Value +Shared_signature_arg.Local_used.+f
  $ grep -m1 -oF -- 'Dead Value +Shared_signature_arg.Local_used.+f' regression.out
  [1]

A parameter access must not suppress an ordinary access from the same binding, regardless of which occurrence the mapper visits first.

  $ grep -m1 -oF -- 'Live Value +Reference_order.Parameter_first.Used.+f' regression.out
  Live Value +Reference_order.Parameter_first.Used.+f
  $ grep -m1 -oF -- 'Dead Value +Reference_order.Parameter_first.Used.+f' regression.out
  [1]
  $ grep -m1 -oF -- 'Live Value +Reference_order.Ordinary_first.Used.+f' regression.out
  Live Value +Reference_order.Ordinary_first.Used.+f
  $ grep -m1 -oF -- 'Dead Value +Reference_order.Ordinary_first.Used.+f' regression.out
  [1]

A call through a functor parameter is credited to the actual argument (conservatively, to every implementation of the item, before OCaml 5.3): x must never be reported unused.

  $ grep -m1 -oF -- 'optional argument x of function Opt_chosen.+g is never used' regression.out
  [1]

Arguments wrapped in a constraint by a named module type are still used.

  $ grep -m1 -oF -- 'Live Value +Shared_signature_arg.Chosen2.+f' regression.out
  Live Value +Shared_signature_arg.Chosen2.+f

Arguments of generative functors and applied arguments are used.

  $ grep -m1 -oF -- 'Live Value +Shared_signature_arg.Opt_unit_first.+g' regression.out
  Live Value +Shared_signature_arg.Opt_unit_first.+g
  $ grep -m1 -oF -- 'Live Value +Shared_signature_arg.Opt_unit_last.+g' regression.out
  Live Value +Shared_signature_arg.Opt_unit_last.+g
  $ grep -m1 -oF -- 'Live Value +Shared_signature_arg.Mk_o.+g' regression.out
  Live Value +Shared_signature_arg.Mk_o.+g
  $ grep -m1 -oF -- 'Live Value +Shared_signature_arg.Fwd_used.+f' regression.out
  Live Value +Shared_signature_arg.Fwd_used.+f
  $ grep -m1 -oF -- 'Live Value +Shared_signature_arg.Applied_struct.+g' regression.out
  Live Value +Shared_signature_arg.Applied_struct.+g
  $ grep -m1 -oF -- 'Live Value +Higher_order.Opt_ho.+g' regression.out
  Live Value +Higher_order.Opt_ho.+g
  $ grep -m1 -oF -- 'Live Value +Higher_order.Opt_fc.+g' regression.out
  Live Value +Higher_order.Opt_fc.+g
  $ grep -m1 -oF -- 'Live Value +Higher_order.P_esc.+h' regression.out
  Live Value +Higher_order.P_esc.+h
  $ grep -m1 -oF -- 'Live Value +Higher_order.Id_used.+f' regression.out
  Live Value +Higher_order.Id_used.+f
  $ grep -m1 -oF -- 'Dead Value +Shared_signature_arg.Chosen2.+f' regression.out
  [1]
  $ grep -m1 -oF -- 'Dead Value +Shared_signature_arg.Opt_constrained.+g' regression.out
  [1]
  $ grep -m1 -oF -- 'Parent is a dead module' regression.out
  [1]
  $ grep -m1 -oF -- 'Dead Value +Functor_argument.Ordered.+compare' regression.out
  [1]
  $ grep -m1 -oF -- 'Live Value +Functor_argument.Ordered.+unused' regression.out
  [1]
  $ grep -m1 -oF -- 'Dead Value +Functor_argument.Anonymous_set.+compare' regression.out
  [1]
  $ grep -m1 -oF -- 'Live Value +Functor_argument.Anonymous_set.+unused' regression.out
  [1]
  $ grep -m1 -oF -- 'Dead Value +Local_side_effects.+_info' regression.out
  [1]
  $ grep -m1 -oF -- 'Dead Value +Local_side_effects.+process' regression.out
  [1]
  $ grep -m1 -oF -- 'Dead Value +Local_side_effects.+register' regression.out
  [1]
  $ grep -m1 -oF -- 'Live Value +Dup_a_impl.Make.+f' all.out
  Live Value +Dup_a_impl.Make.+f
  $ grep -m1 -oF -- 'Dead Value +Dup_a_impl.Make.+g' all.out
  Dead Value +Dup_a_impl.Make.+g
  $ grep -m1 -oF -- 'Dead Value +Dup_b_impl.Make.+f' all.out
  Dead Value +Dup_b_impl.Make.+f
  $ grep -m1 -oF -- 'Live Value +Dup_b_impl.Make.+g' all.out
  Live Value +Dup_b_impl.Make.+g
  $ grep -m1 -oF -- 'Dead Value +Dup_b_impl.Make.+h' all.out
  Dead Value +Dup_b_impl.Make.+h
  $ grep -m1 -oF -- 'Dead Value +Dup_a_impl.Make.+f' all.out
  [1]
  $ grep -m1 -oF -- 'Dead Value +Dup_b_impl.Make.+g' all.out
  [1]
