Regression fixtures in examples/regression whose results need OCaml 5.3
or later (shapes). Each grep prints a line the analysis must report; [1]
marks one it must not report.

  $ cp -r ../examples/regression . && cd regression
  $ dune build --root . 2>&1

  $ reanalyze.exe -ci -debug -native-build-target . -dce-cmt _build/default/exception_collision/.exception_collision.objs/byte > exception_collision.out 2>/dev/null
  $ reanalyze.exe -ci -debug -native-build-target . -dce-cmt _build/default/src/.regression_fixture.objs/byte > regression.out 2>/dev/null
  $ reanalyze.exe -ci -debug -native-build-target . -dce-cmt _build/default > all.out 2>/dev/null

Before 5.3 the conservative fallback keeps both included items live.

  $ grep -m1 -oF -- 'Dead Value +IncludeSigMli.+hash' regression.out
  Dead Value +IncludeSigMli.+hash
  $ grep -m1 -oF -- 'Live Value +IncludeSigMli.+hash' regression.out
  [1]

A type re-export (type t = M.t = A | B) shares its constructors and labels with the original: constructing or reading through either name keeps both declarations live, also when M is a local module alias. The original is found through shapes.

  $ grep -m1 -oF -- 'Live VariantCase +Type_reexport.change.Built_through_reexport:' regression.out
  Live VariantCase +Type_reexport.change.Built_through_reexport:
  $ grep -m1 -oF -- 'Dead VariantCase +Type_reexport.change.Built_through_reexport:' regression.out
  [1]
  $ grep -m1 -oF -- 'Live VariantCase +Type_reexport.change.Built_directly:' regression.out
  Live VariantCase +Type_reexport.change.Built_directly:
  $ grep -m1 -oF -- 'Dead VariantCase +Type_reexport.change.Built_directly:' regression.out
  [1]
  $ grep -m1 -oF -- 'Live VariantCase +Type_reexport_orig.change.Built_through_reexport:' regression.out
  Live VariantCase +Type_reexport_orig.change.Built_through_reexport:
  $ grep -m1 -oF -- 'Dead VariantCase +Type_reexport_orig.change.Built_through_reexport:' regression.out
  [1]
  $ grep -m1 -oF -- 'Live VariantCase +Type_reexport_orig.change.Built_directly:' regression.out
  Live VariantCase +Type_reexport_orig.change.Built_directly:
  $ grep -m1 -oF -- 'Dead VariantCase +Type_reexport_orig.change.Built_directly:' regression.out
  [1]
  $ grep -m1 -oF -- 'Live RecordLabel +Type_reexport.job.read_through_original:' regression.out
  Live RecordLabel +Type_reexport.job.read_through_original:
  $ grep -m1 -oF -- 'Dead RecordLabel +Type_reexport.job.read_through_original:' regression.out
  [1]
  $ grep -m1 -oF -- 'Live RecordLabel +Type_reexport.job.read_through_reexport:' regression.out
  Live RecordLabel +Type_reexport.job.read_through_reexport:
  $ grep -m1 -oF -- 'Dead RecordLabel +Type_reexport.job.read_through_reexport:' regression.out
  [1]
  $ grep -m1 -oF -- 'Live RecordLabel +Type_reexport.job.read_through_alias:' regression.out
  Live RecordLabel +Type_reexport.job.read_through_alias:
  $ grep -m1 -oF -- 'Dead RecordLabel +Type_reexport.job.read_through_alias:' regression.out
  [1]
  $ grep -m1 -oF -- 'Dead RecordLabel +Type_reexport.job.never_read:' regression.out
  Dead RecordLabel +Type_reexport.job.never_read:
  $ grep -m1 -oF -- 'Live RecordLabel +Type_reexport_orig.job.read_through_original:' regression.out
  Live RecordLabel +Type_reexport_orig.job.read_through_original:
  $ grep -m1 -oF -- 'Dead RecordLabel +Type_reexport_orig.job.read_through_original:' regression.out
  [1]
  $ grep -m1 -oF -- 'Live RecordLabel +Type_reexport_orig.job.read_through_reexport:' regression.out
  Live RecordLabel +Type_reexport_orig.job.read_through_reexport:
  $ grep -m1 -oF -- 'Dead RecordLabel +Type_reexport_orig.job.read_through_reexport:' regression.out
  [1]
  $ grep -m1 -oF -- 'Live RecordLabel +Type_reexport_orig.job.read_through_alias:' regression.out
  Live RecordLabel +Type_reexport_orig.job.read_through_alias:
  $ grep -m1 -oF -- 'Dead RecordLabel +Type_reexport_orig.job.read_through_alias:' regression.out
  [1]
  $ grep -m1 -oF -- 'Dead RecordLabel +Type_reexport_orig.job.never_read:' regression.out
  Dead RecordLabel +Type_reexport_orig.job.never_read:
  $ grep -m1 -oF -- 'Live RecordLabel +Type_reexport_alias.job.read_through_original:' regression.out
  Live RecordLabel +Type_reexport_alias.job.read_through_original:
  $ grep -m1 -oF -- 'Dead RecordLabel +Type_reexport_alias.job.read_through_original:' regression.out
  [1]
  $ grep -m1 -oF -- 'Live RecordLabel +Type_reexport_alias.job.read_through_reexport:' regression.out
  Live RecordLabel +Type_reexport_alias.job.read_through_reexport:
  $ grep -m1 -oF -- 'Dead RecordLabel +Type_reexport_alias.job.read_through_reexport:' regression.out
  [1]
  $ grep -m1 -oF -- 'Live RecordLabel +Type_reexport_alias.job.read_through_alias:' regression.out
  Live RecordLabel +Type_reexport_alias.job.read_through_alias:
  $ grep -m1 -oF -- 'Dead RecordLabel +Type_reexport_alias.job.read_through_alias:' regression.out
  [1]
  $ grep -m1 -oF -- 'Dead RecordLabel +Type_reexport_alias.job.never_read:' regression.out
  Dead RecordLabel +Type_reexport_alias.job.never_read:
  $ grep -m1 -oF -- 'Dead VariantCase +Type_reexport.change.Never_built:' regression.out
  Dead VariantCase +Type_reexport.change.Never_built:
  $ grep -m1 -oF -- 'Dead VariantCase +Type_reexport_orig.change.Never_built:' regression.out
  Dead VariantCase +Type_reexport_orig.change.Never_built:

Precise attribution through a shared named module type relies on shape reduction of identifier occurrences, available from OCaml 5.3. Earlier versions conservatively keep every implementation of the item live.

  $ grep -m1 -oF -- 'Dead Value +Shared_signature_unused.Make.+f' regression.out
  Dead Value +Shared_signature_unused.Make.+f
  $ grep -m1 -oF -- 'Live Value +Shared_signature_unused.Make.+f' regression.out
  [1]
  $ grep -m1 -oF -- 'Dead Value +Shared_signature_arg.Ignored.+f' regression.out
  Dead Value +Shared_signature_arg.Ignored.+f
  $ grep -m1 -oF -- 'Live Value +Shared_signature_arg.Ignored.+f' regression.out
  [1]
  $ grep -m1 -oF -- 'Dead Value +Shared_signature_arg.Local_unused.+f' regression.out
  Dead Value +Shared_signature_arg.Local_unused.+f
  $ grep -m1 -oF -- 'Live Value +Shared_signature_arg.Local_unused.+f' regression.out
  [1]

A call through a functor parameter supplying ?x must not be attributed to other implementations of the module type item.

  $ grep -m1 -oF -- 'optional argument x of function Opt_direct.+g is never used' regression.out
  optional argument x of function Opt_direct.+g is never used

... and is credited precisely, including through a constraint, for an inline functor, and for a functor with a whole-functor signature.

  $ grep -m1 -oF -- 'optional argument x of function Opt_chosen.+g is always supplied' regression.out
  optional argument x of function Opt_chosen.+g is always supplied
  $ grep -m1 -oF -- 'optional argument x of function Opt_sigfun.+g is always supplied' regression.out
  optional argument x of function Opt_sigfun.+g is always supplied

... through a named partial application, and for a let-module functor.

  $ grep -m1 -oF -- 'optional argument x of function Opt_partial.+g is always supplied' regression.out
  optional argument x of function Opt_partial.+g is always supplied
  $ grep -m1 -oF -- 'optional argument x of function Opt_letmodule.+g is always supplied' regression.out
  optional argument x of function Opt_letmodule.+g is always supplied

... through an alias of the parameter, and for a recursive functor. The aliased call must not leak to another implementation.

  $ grep -m1 -oF -- 'optional argument x of function Opt_alias.+g is always supplied' regression.out
  optional argument x of function Opt_alias.+g is always supplied
  $ grep -m1 -oF -- 'optional argument x of function Opt_alias_other.+g is never used' regression.out
  optional argument x of function Opt_alias_other.+g is never used
  $ grep -m1 -oF -- 'optional argument x of function Opt_rec.+g is always supplied' regression.out
  optional argument x of function Opt_rec.+g is always supplied

Argument constrained by an alias of the module type; a functor forwarding its parameter to another functor; include of the parameter.

  $ grep -m1 -oF -- 'Live Value +Shared_signature_arg.Chosen3.+f' regression.out
  Live Value +Shared_signature_arg.Chosen3.+f
  $ grep -m1 -oF -- 'Dead Value +Shared_signature_arg.Ignored3.+f' regression.out
  Dead Value +Shared_signature_arg.Ignored3.+f
  $ grep -m1 -oF -- 'Live Value +Shared_signature_arg.Chosen4.+f' regression.out
  Live Value +Shared_signature_arg.Chosen4.+f
  $ grep -m1 -oF -- 'Dead Value +Shared_signature_arg.Ignored4.+f' regression.out
  Dead Value +Shared_signature_arg.Ignored4.+f
  $ grep -m1 -oF -- 'optional argument x of function Opt_outer.+g is always supplied' regression.out
  optional argument x of function Opt_outer.+g is always supplied
  $ grep -m1 -oF -- 'optional argument x of function Opt_incl.+g is always supplied' regression.out
  optional argument x of function Opt_incl.+g is always supplied
  $ grep -m1 -oF -- 'optional argument x of function Opt_incl_other.+g is never used' regression.out
  optional argument x of function Opt_incl_other.+g is never used

A module type declared inside a module.

  $ grep -m1 -oF -- 'Live Value +Nested_module_type.Outer.Used.+f' regression.out
  Live Value +Nested_module_type.Outer.Used.+f
  $ grep -m1 -oF -- 'Dead Value +Nested_module_type.Outer.Unused.+f' regression.out
  Dead Value +Nested_module_type.Outer.Unused.+f

let-module alias of a functor; module type aliases rooted at a local module and shadowing a same-named module type.

  $ grep -m1 -oF -- 'optional argument x of function Opt_letalias.+g is always supplied' regression.out
  optional argument x of function Opt_letalias.+g is always supplied
  $ grep -m1 -oF -- 'Live Value +Shared_signature_arg.Use_t.+h' regression.out
  Live Value +Shared_signature_arg.Use_t.+h
  $ grep -m1 -oF -- 'Live Value +Shared_signature_arg.Shadow.Use3.+k' regression.out
  Live Value +Shared_signature_arg.Shadow.Use3.+k

A nested module of the parameter constrained by a named module type.

  $ grep -m1 -oF -- 'Live Value +Shared_signature_arg.Nested_arg.N.+g' regression.out
  Live Value +Shared_signature_arg.Nested_arg.N.+g
  $ grep -m1 -oF -- 'optional argument x of function Nested_arg.N.+g is always supplied' regression.out
  optional argument x of function Nested_arg.N.+g is always supplied
  $ grep -m1 -oF -- 'optional argument x of function Nested_other.N.+g is never used' regression.out
  optional argument x of function Nested_other.N.+g is never used

Ten forwarding functors; modules inside a functor body; an alias of a functor defined in another file; a module type in an included signature.

  $ grep -m1 -oF -- 'optional argument x of function Opt_chain.+g is always supplied' regression.out
  optional argument x of function Opt_chain.+g is always supplied
  $ grep -m1 -oF -- 'Dead Value +Shared_signature_arg.Apply_in_body.Ignored_in.+f' regression.out
  Dead Value +Shared_signature_arg.Apply_in_body.Ignored_in.+f
  $ grep -m1 -oF -- 'Live Value +Shared_signature_arg.Apply_in_body.Chosen_in.+f' regression.out
  Live Value +Shared_signature_arg.Apply_in_body.Chosen_in.+f
  $ grep -m1 -oF -- 'optional argument x of function Opt_cross.+g is always supplied' regression.out
  optional argument x of function Opt_cross.+g is always supplied
  $ grep -m1 -oF -- 'Live Value +Included_sig.M.+f' regression.out
  Live Value +Included_sig.M.+f

A module type nested in a with-constrained signature; nine aliases.

  $ grep -m1 -oF -- 'Live Value +Included_sig.W.X.+f' regression.out
  Live Value +Included_sig.W.X.+f
  $ grep -m1 -oF -- 'optional argument x of function Opt_alias9.+g is always supplied' regression.out
  optional argument x of function Opt_alias9.+g is always supplied

A nested functor applied through Outer (A).Inner; a recursive alias.

  $ grep -m1 -oF -- 'optional argument x of function Opt_ext.+g is always supplied' regression.out
  optional argument x of function Opt_ext.+g is always supplied
  $ grep -m1 -oF -- 'optional argument x of function Opt_rec_alias.+g is always supplied' regression.out
  optional argument x of function Opt_rec_alias.+g is always supplied

A recursive alias of the parameter; a module type introduced by a with-constraint.

  $ grep -m1 -oF -- 'optional argument x of function Opt_recalias.+g is always supplied' regression.out
  optional argument x of function Opt_recalias.+g is always supplied
  $ grep -m1 -oF -- 'optional argument x of function Opt_recalias_other.+g is never used' regression.out
  optional argument x of function Opt_recalias_other.+g is never used
  $ grep -m1 -oF -- 'Live Value +Included_sig.W2.X.+f' regression.out
  Live Value +Included_sig.W2.X.+f

module type of; a nested functor obtained through include.

  $ grep -m1 -oF -- 'Live Value +Included_sig.W3.X.+f' regression.out
  Live Value +Included_sig.W3.X.+f
  $ grep -m1 -oF -- 'optional argument x of function Opt_incl_f.+g is always supplied' regression.out
  optional argument x of function Opt_incl_f.+g is always supplied
  $ grep -m1 -oF -- 'optional argument x of function Opt_cross_incl.+g is always supplied' regression.out
  optional argument x of function Opt_cross_incl.+g is always supplied
  $ grep -m1 -oF -- 'optional argument x of function Opt_rec_chain.+g is always supplied' regression.out
  optional argument x of function Opt_rec_chain.+g is always supplied
  $ grep -m1 -oF -- 'optional argument x of function Opt_y.+g is always supplied' regression.out
  optional argument x of function Opt_y.+g is always supplied

A module type rooted at a functor application.

  $ grep -m1 -oF -- 'Live Value +Shared_signature_arg.Used_mt.+f' regression.out
  Live Value +Shared_signature_arg.Used_mt.+f
  $ grep -m1 -oF -- 'Dead Value +Shared_signature_arg.Unused_mt.+f' regression.out
  Dead Value +Shared_signature_arg.Unused_mt.+f

Module types rooted at a functor parameter: M.T, M.Sub.T2, Outer (M).SM, through a parameter alias, and through include.

  $ grep -m1 -oF -- 'Live Value +Shared_signature_arg.Apply_pt.Use_p.+f' regression.out
  Live Value +Shared_signature_arg.Apply_pt.Use_p.+f
  $ grep -m1 -oF -- 'Dead Value +Shared_signature_arg.Apply_pt.Unused_p.+f' regression.out
  Dead Value +Shared_signature_arg.Apply_pt.Unused_p.+f
  $ grep -m1 -oF -- 'Live Value +Shared_signature_arg.Apply_pt.Use_p2.+h' regression.out
  Live Value +Shared_signature_arg.Apply_pt.Use_p2.+h
  $ grep -m1 -oF -- 'Live Value +Shared_signature_arg.Apply_app.Use_a.+f' regression.out
  Live Value +Shared_signature_arg.Apply_app.Use_a.+f
  $ grep -m1 -oF -- 'Dead Value +Shared_signature_arg.Apply_app.Unused_a.+f' regression.out
  Dead Value +Shared_signature_arg.Apply_app.Unused_a.+f
  $ grep -m1 -oF -- 'Live Value +Shared_signature_arg.Apply_pt2.Use_alias_mt.+f' regression.out
  Live Value +Shared_signature_arg.Apply_pt2.Use_alias_mt.+f
  $ grep -m1 -oF -- 'Live Value +Shared_signature_arg.Apply_pt2.Use_include_mt.+f' regression.out
  Live Value +Shared_signature_arg.Apply_pt2.Use_include_mt.+f

Module types through an aliased or applied member of an applied functor's result.

  $ grep -m1 -oF -- 'Live Value +Shared_signature_arg.Use_u.+f' regression.out
  Live Value +Shared_signature_arg.Use_u.+f
  $ grep -m1 -oF -- 'Live Value +Shared_signature_arg.Use_u2.+k' regression.out
  Live Value +Shared_signature_arg.Use_u2.+k

A forward alias of the parameter in a recursive group.

  $ grep -m1 -oF -- 'optional argument x of function Opt_recfwd.+g is always supplied' regression.out
  optional argument x of function Opt_recfwd.+g is always supplied
  $ grep -m1 -oF -- 'optional argument x of function Opt_recfwd_other.+g is never used' regression.out
  optional argument x of function Opt_recfwd_other.+g is never used

Sweep of parameter-alias forms: recursive alias of a parameter's submodule, let-module alias chain, recursive alias of an outer alias, alias passed as a functor argument. Each credited exactly once and never leaked to an unrelated implementation.

  $ grep -m1 -oF -- 'optional argument x of function Opt_sw1.+g is always supplied (1 calls)' regression.out
  optional argument x of function Opt_sw1.+g is always supplied (1 calls)
  $ grep -m1 -oF -- 'optional argument x of function Opt_sw2.+g is always supplied (1 calls)' regression.out
  optional argument x of function Opt_sw2.+g is always supplied (1 calls)
  $ grep -m1 -oF -- 'optional argument x of function Opt_sw3.+g is always supplied (1 calls)' regression.out
  optional argument x of function Opt_sw3.+g is always supplied (1 calls)
  $ grep -m1 -oF -- 'optional argument x of function Opt_sw4.+g is always supplied (1 calls)' regression.out
  optional argument x of function Opt_sw4.+g is always supplied (1 calls)
  $ grep -m1 -oF -- 'optional argument x of function Opt_sw_other.+g is never used' regression.out
  optional argument x of function Opt_sw_other.+g is never used

Arguments constrained by a module type from outside the analysis root (Set.OrderedType): inline and named.

  $ grep -m1 -oF -- 'Live Value +Shared_signature_arg.Applied_ord.+compare' regression.out
  Live Value +Shared_signature_arg.Applied_ord.+compare
  $ grep -m1 -oF -- 'Live Value +Shared_signature_arg.Ord_named.+compare' regression.out
  Live Value +Shared_signature_arg.Ord_named.+compare

Module types inside an applied inline functor and inside a functor parameter's type: their items are never declarations.

  $ grep -m1 -oF -- 'Live Value +Shared_signature_arg.M_app.X.+f' regression.out
  Live Value +Shared_signature_arg.M_app.X.+f
  $ grep -m1 -oF -- 'Live Value +Shared_signature_arg.Arg_p.X.+f' regression.out
  Live Value +Shared_signature_arg.Arg_p.X.+f

(Arg_p2.X.f is live: an argument's coerced items count as used.)

  $ grep -m1 -oF -- 'Value +Shared_signature_arg.Applied_fp2.X.+f' regression.out
  [1]
  $ grep -m1 -oF -- 'Value +Shared_signature_arg.F_param.X.+f' regression.out
  [1]

Constraint-wrapped right-hand sides: a recursive constrained partial application, and a let-module constrained functor.

  $ grep -m1 -oF -- 'optional argument x of function Opt_recc.+g is always supplied (1 calls)' regression.out
  optional argument x of function Opt_recc.+g is always supplied (1 calls)
  $ grep -m1 -oF -- 'optional argument x of function Opt_letc.+g is always supplied (1 calls)' regression.out
  optional argument x of function Opt_letc.+g is always supplied (1 calls)

Partial applications: held by a let module, and bound in another file.

  $ grep -m1 -oF -- 'optional argument x of function Opt_letpartial.+g is always supplied' regression.out
  optional argument x of function Opt_letpartial.+g is always supplied
  $ grep -m1 -oF -- 'optional argument x of function Opt_cross_partial.+g is always supplied' regression.out
  optional argument x of function Opt_cross_partial.+g is always supplied
  $ grep -m1 -oF -- 'optional argument x of function Opt_constrained.+g is always supplied' regression.out
  optional argument x of function Opt_constrained.+g is always supplied
  $ grep -m1 -oF -- 'optional argument x of function Opt_inline.+g is always supplied' regression.out
  optional argument x of function Opt_inline.+g is always supplied
  $ grep -m1 -oF -- 'Dead Value +Shared_signature_arg.Ignored2.+f' regression.out
  Dead Value +Shared_signature_arg.Ignored2.+f

Generative functors: a unit application first, in the middle, last, in a partial application, a recursive binding, a let module, and bound in another file. An implementation never applied keeps its unused argument.

  $ grep -m1 -oF -- 'optional argument x of function Opt_unit_first.+g is always supplied (1 calls)' regression.out
  optional argument x of function Opt_unit_first.+g is always supplied (1 calls)
  $ grep -m1 -oF -- 'optional argument x of function Opt_unit_mid.+g is always supplied (1 calls)' regression.out
  optional argument x of function Opt_unit_mid.+g is always supplied (1 calls)
  $ grep -m1 -oF -- 'optional argument x of function Opt_unit_last.+g is always supplied (1 calls)' regression.out
  optional argument x of function Opt_unit_last.+g is always supplied (1 calls)
  $ grep -m1 -oF -- 'optional argument x of function Opt_unit_partial.+g is always supplied (1 calls)' regression.out
  optional argument x of function Opt_unit_partial.+g is always supplied (1 calls)
  $ grep -m1 -oF -- 'optional argument x of function Opt_unit_end.+g is always supplied (1 calls)' regression.out
  optional argument x of function Opt_unit_end.+g is always supplied (1 calls)
  $ grep -m1 -oF -- 'optional argument x of function Opt_unit_rec.+g is always supplied (1 calls)' regression.out
  optional argument x of function Opt_unit_rec.+g is always supplied (1 calls)
  $ grep -m1 -oF -- 'optional argument x of function Opt_unit_let.+g is always supplied (1 calls)' regression.out
  optional argument x of function Opt_unit_let.+g is always supplied (1 calls)
  $ grep -m1 -oF -- 'optional argument x of function Opt_cross_unit.+g is always supplied (1 calls)' regression.out
  optional argument x of function Opt_cross_unit.+g is always supplied (1 calls)
  $ grep -m1 -oF -- 'optional argument x of function Opt_cross_unit2.+g is always supplied (1 calls)' regression.out
  optional argument x of function Opt_cross_unit2.+g is always supplied (1 calls)
  $ grep -m1 -oF -- 'optional argument x of function Opt_unit_none.+g is never used' regression.out
  optional argument x of function Opt_unit_none.+g is never used

Arguments that are themselves applications: directly, constrained, curried, nested, generative, through an alias of the functor, with a parameter as the inner argument, of an inline functor, bound in another file, and a constrained inline structure. The calls are credited to the applied functor's body only.

  $ grep -m1 -oF -- 'optional argument x of function Mk_o.+g is always supplied (1 calls)' regression.out
  optional argument x of function Mk_o.+g is always supplied (1 calls)
  $ grep -m1 -oF -- 'optional argument x of function Mk_o_c.+g is always supplied (1 calls)' regression.out
  optional argument x of function Mk_o_c.+g is always supplied (1 calls)
  $ grep -m1 -oF -- 'optional argument x of function Mk_o2.+g is always supplied (1 calls)' regression.out
  optional argument x of function Mk_o2.+g is always supplied (1 calls)
  $ grep -m1 -oF -- 'optional argument x of function Mk_o_n.+g is always supplied (1 calls)' regression.out
  optional argument x of function Mk_o_n.+g is always supplied (1 calls)
  $ grep -m1 -oF -- 'optional argument x of function Mk_o_unit.+g is always supplied (1 calls)' regression.out
  optional argument x of function Mk_o_unit.+g is always supplied (1 calls)
  $ grep -m1 -oF -- 'optional argument x of function Mk_o_a.+g is always supplied (1 calls)' regression.out
  optional argument x of function Mk_o_a.+g is always supplied (1 calls)
  $ grep -m1 -oF -- 'optional argument x of function Mk_o_p.+g is always supplied (1 calls)' regression.out
  optional argument x of function Mk_o_p.+g is always supplied (1 calls)
  $ grep -m1 -oF -- 'optional argument x of function Applied_app_inline.+g is always supplied (1 calls)' regression.out
  optional argument x of function Applied_app_inline.+g is always supplied (1 calls)
  $ grep -m1 -oF -- 'optional argument x of function Applied_struct.+g is always supplied (1 calls)' regression.out
  optional argument x of function Applied_struct.+g is always supplied (1 calls)
  $ grep -m1 -oF -- 'optional argument x of function Mk_cross.+g is always supplied (2 calls)' regression.out
  optional argument x of function Mk_cross.+g is always supplied (2 calls)
  $ grep -m1 -oF -- 'optional argument x of function Mk_o_none.+g is never used' regression.out
  optional argument x of function Mk_o_none.+g is never used

An applied functor re-exporting its argument: the argument's value is used, another implementation of the module type stays dead.

  $ grep -m1 -oF -- 'Live Value +Shared_signature_arg.Fwd_used.+f' regression.out
  Live Value +Shared_signature_arg.Fwd_used.+f
  $ grep -m1 -oF -- 'Dead Value +Shared_signature_arg.Fwd_unused.+f' regression.out
  Dead Value +Shared_signature_arg.Fwd_unused.+f

Higher-order functors: a functor passed as an argument and applied in the body, to a parameter, a fixed module, a submodule of a parameter, through an alias of the functor parameter, in an include, partially applied beforehand, through two levels; and first-class modules as head and as argument, in the same file and from another file. Each call is credited to the argument of the same application only.

  $ grep -m1 -oF -- 'optional argument x of function Opt_ho.+g is always supplied (1 calls)' regression.out
  optional argument x of function Opt_ho.+g is always supplied (1 calls)
  $ grep -m1 -oF -- 'optional argument x of function Opt_fixed.+g is always supplied (1 calls)' regression.out
  optional argument x of function Opt_fixed.+g is always supplied (1 calls)
  $ grep -m1 -oF -- 'optional argument x of function Opt_sub_holder.Sub.+g is always supplied (1 calls)' regression.out
  optional argument x of function Opt_sub_holder.Sub.+g is always supplied (1 calls)
  $ grep -m1 -oF -- 'optional argument x of function Opt_alias_ho.+g is always supplied (1 calls)' regression.out
  optional argument x of function Opt_alias_ho.+g is always supplied (1 calls)
  $ grep -m1 -oF -- 'optional argument x of function Opt_incl_ho.+g is always supplied (1 calls)' regression.out
  optional argument x of function Opt_incl_ho.+g is always supplied (1 calls)
  $ grep -m1 -oF -- 'optional argument x of function Opt_partial_ho.+g is always supplied (1 calls)' regression.out
  optional argument x of function Opt_partial_ho.+g is always supplied (1 calls)
  $ grep -m1 -oF -- 'optional argument x of function Opt_2.+g is always supplied (1 calls)' regression.out
  optional argument x of function Opt_2.+g is always supplied (1 calls)
  $ grep -m1 -oF -- 'optional argument x of function Opt_fc.+g is always supplied (1 calls)' regression.out
  optional argument x of function Opt_fc.+g is always supplied (1 calls)
  $ grep -m1 -oF -- 'optional argument x of function Opt_fca.+g is always supplied (1 calls)' regression.out
  optional argument x of function Opt_fca.+g is always supplied (1 calls)
  $ grep -m1 -oF -- 'optional argument x of function Opt_cross_fc.+g is always supplied (1 calls)' regression.out
  optional argument x of function Opt_cross_fc.+g is always supplied (1 calls)
  $ grep -m1 -oF -- 'optional argument x of function Opt_id.+g is always supplied (1 calls)' regression.out
  optional argument x of function Opt_id.+g is always supplied (1 calls)
  $ grep -m1 -oF -- 'optional argument x of function Opt_twice.+g is always supplied (2 calls)' regression.out
  optional argument x of function Opt_twice.+g is always supplied (2 calls)

... a functor whose body is directly the parameter's application, and a higher-order functor from another file applied to a functor from a third file.

  $ grep -m1 -oF -- 'optional argument x of function Opt_direct_body.+g is always supplied (1 calls)' regression.out
  optional argument x of function Opt_direct_body.+g is always supplied (1 calls)
  $ grep -m1 -oF -- 'optional argument x of function Opt_cross_ho.+g is always supplied (1 calls)' regression.out
  optional argument x of function Opt_cross_ho.+g is always supplied (1 calls)

... and with the functor parameter's type written inline: the passed functor's values used through it stay live, its unused helper dead.

  $ grep -m1 -oF -- 'optional argument x of function Opt_anon.+g is always supplied (1 calls)' regression.out
  optional argument x of function Opt_anon.+g is always supplied (1 calls)
  $ grep -m1 -oF -- 'Live Value +Higher_order_more.Impl_anon.+run' regression.out
  Live Value +Higher_order_more.Impl_anon.+run
  $ grep -m1 -oF -- 'Dead Value +Higher_order_more.Impl_anon.+helper' regression.out
  Dead Value +Higher_order_more.Impl_anon.+helper
  $ grep -m1 -oF -- 'optional argument x of function Opt_none_ho.+g is never used' regression.out
  optional argument x of function Opt_none_ho.+g is never used

Inline functors returning (a submodule of) their parameter, or a functor applied to it: the argument flows on; an unrelated implementation stays dead.

  $ grep -m1 -oF -- 'Live Value +Higher_order.Id_used.+f' regression.out
  Live Value +Higher_order.Id_used.+f
  $ grep -m1 -oF -- 'Live Value +Higher_order.Id_sub_holder.Sub.+f' regression.out
  Live Value +Higher_order.Id_sub_holder.Sub.+f
  $ grep -m1 -oF -- 'Live Value +Higher_order.Id_app.+f' regression.out
  Live Value +Higher_order.Id_app.+f
  $ grep -m1 -oF -- 'Live Value +Higher_order.Id_curried.+f' regression.out
  Live Value +Higher_order.Id_curried.+f
  $ grep -m1 -oF -- 'Dead Value +Higher_order.Id_unused.+f' regression.out
  Dead Value +Higher_order.Id_unused.+f

A functor escaping as a first-class module passed to a function: its calls are forwarded conservatively, never dropped.

  $ grep -m1 -oF -- 'optional argument y of function P_esc.+h is always supplied' regression.out
  optional argument y of function P_esc.+h is always supplied
  $ grep -m1 -oF -- 'P_esc.+h is never used' regression.out
  [1]

... including functors nested in a module that escapes, nested in the result of an applied functor parameter, and a functor applied directly whose packed value also flows through a function.

  $ grep -m1 -oF -- 'optional argument z of function P2_esc.+k is always supplied' regression.out
  optional argument z of function P2_esc.+k is always supplied
  $ grep -m1 -oF -- 'P2_esc.+k is never used' regression.out
  [1]
  $ grep -m1 -oF -- 'optional argument cross of function Cross_esc.+k is always supplied' regression.out
  optional argument cross of function Cross_esc.+k is always supplied
  $ grep -m1 -oF -- 'Cross_esc.+k is never used' regression.out
  [1]
  $ grep -m1 -oF -- 'optional argument w of function P3_esc.+q is always supplied' regression.out
  optional argument w of function P3_esc.+q is always supplied
  $ grep -m1 -oF -- 'P3_esc.+q is never used' regression.out
  [1]
  $ grep -m1 -oF -- 'optional argument v of function P4_b.+u is always supplied' regression.out
  optional argument v of function P4_b.+u is always supplied
  $ grep -m1 -oF -- 'P4_b.+u is never used' regression.out
  [1]
  $ grep -m1 -oF -- 'P4_a.+u is never used' regression.out
  [1]

New enclosing applications discovered on later fixed-point rounds still instantiate the original parameter-headed application.

  $ grep -m1 -oF -- 'optional argument y of function Fixpoint_a.+g is always supplied (1 calls)' regression.out
  optional argument y of function Fixpoint_a.+g is always supplied (1 calls)
  $ grep -m1 -oF -- 'optional argument y of function Fixpoint_b.+g is always supplied (1 calls)' regression.out
  optional argument y of function Fixpoint_b.+g is always supplied (1 calls)

The two indirect applications share a source application ID but not an enclosing context: C's omitted argument must not mix with B's call.

  $ grep -m1 -oF -- 'optional argument y of function Fixpoint_c.+g is never used' regression.out
  optional argument y of function Fixpoint_c.+g is never used

A packed higher-order argument exported through an .mli resolves to the implementation binding where its functor was registered.

  $ grep -m1 -oF -- 'optional argument x of function Packed_arg.+g is always supplied (1 calls)' regression.out
  optional argument x of function Packed_arg.+g is always supplied (1 calls)

A foreign unpacked functor (and its alias) has no shape uid. Resolve its packed binding precisely; an unpacked include escapes instead.

  $ grep -m1 -oF -- 'optional argument x of function Unpacked_arg.+g is always supplied (1 calls)' regression.out
  optional argument x of function Unpacked_arg.+g is always supplied (1 calls)
  $ grep -m1 -oF -- 'optional argument x of function Unpacked_unused.+g is never used' regression.out
  optional argument x of function Unpacked_unused.+g is never used
  $ grep -m1 -oF -- 'optional argument included of function Unpacked_include_arg.+g is always supplied (1 calls)' regression.out
  optional argument included of function Unpacked_include_arg.+g is always supplied (1 calls)
  $ grep -m1 -oF -- 'optional argument nested of function Unpacked_nested_arg.+g is always supplied (1 calls)' regression.out
  optional argument nested of function Unpacked_nested_arg.+g is always supplied (1 calls)
  $ grep -m1 -oF -- 'optional argument opened of function Direct.Open_arg.+g is always supplied (1 calls)' regression.out
  optional argument opened of function Direct.Open_arg.+g is always supplied (1 calls)
  $ grep -m1 -oF -- 'optional argument opened of function Local.Local_open_arg.+g is always supplied (1 calls)' regression.out
  optional argument opened of function Local.Local_open_arg.+g is always supplied (1 calls)
  $ grep -m1 -oF -- 'optional argument opened of function Open_struct.Open_struct_arg.+g is always supplied (1 calls)' regression.out
  optional argument opened of function Open_struct.Open_struct_arg.+g is always supplied (1 calls)
  $ grep -m1 -oF -- 'optional argument opened of function Include_struct.Include_struct_arg.+g is always supplied (1 calls)' regression.out
  optional argument opened of function Include_struct.Include_struct_arg.+g is always supplied (1 calls)
  $ grep -m1 -oF -- 'optional argument opened of function Cross_unit.Cross_open_arg.+g is always supplied (1 calls)' regression.out
  optional argument opened of function Cross_unit.Cross_open_arg.+g is always supplied (1 calls)
  $ grep -m1 -oF -- 'optional argument opened of function Mixed_open.Used_arg.+g is always supplied (1 calls)' regression.out
  optional argument opened of function Mixed_open.Used_arg.+g is always supplied (1 calls)
  $ grep -m1 -oF -- 'optional argument unrelated of function Unrelated.Unrelated_arg.+g is never used' regression.out
  optional argument unrelated of function Unrelated.Unrelated_arg.+g is never used
  $ grep -m1 -oF -- 'optional argument unused_open of function Unused_import.Victim.+g is never used' regression.out
  optional argument unused_open of function Unused_import.Victim.+g is never used
  $ grep -m1 -oF -- 'optional argument unused_open of function Unused_import.Called_victim.+g is never used' regression.out
  optional argument unused_open of function Unused_import.Called_victim.+g is never used
  $ grep -m1 -oF -- 'optional argument unused_open of function Mixed_open.Victim.+g is never used' regression.out
  optional argument unused_open of function Mixed_open.Victim.+g is never used
  $ grep -m1 -oF -- 'optional argument aliased of function Aliases.Local_alias_arg.+g is always supplied (1 calls)' regression.out
  optional argument aliased of function Aliases.Local_alias_arg.+g is always supplied (1 calls)
  $ grep -m1 -oF -- 'optional argument foreign_alias of function Aliases.Foreign_alias_arg.+g is always supplied (1 calls)' regression.out
  optional argument foreign_alias of function Aliases.Foreign_alias_arg.+g is always supplied (1 calls)
  $ grep -m1 -oF -- 'optional argument foreign_include of function Aliases.Foreign_include_arg.+g is always supplied (1 calls)' regression.out
  optional argument foreign_include of function Aliases.Foreign_include_arg.+g is always supplied (1 calls)
  $ grep -m1 -oF -- 'optional argument repacked of function Repacked.Repacked_arg.+g is always supplied (1 calls)' regression.out
  optional argument repacked of function Repacked.Repacked_arg.+g is always supplied (1 calls)
  $ grep -m1 -oF -- 'optional argument projected of function Projected.Projected_arg.+g is always supplied (1 calls)' regression.out
  optional argument projected of function Projected.Projected_arg.+g is always supplied (1 calls)
  $ grep -m1 -oF -- 'optional argument opaque of function Opaque_holder.Opaque_arg.+g is always supplied (1 calls)' regression.out
  optional argument opaque of function Opaque_holder.Opaque_arg.+g is always supplied (1 calls)
  $ grep -m1 -oF -- 'optional argument repacked of function Repacked.Repacked_unused.+g is never used' regression.out
  optional argument repacked of function Repacked.Repacked_unused.+g is never used
  $ grep -m1 -oF -- 'optional argument projected of function Projected.Projected_unused.+g is never used' regression.out
  optional argument projected of function Projected.Projected_unused.+g is never used
  $ grep -m1 -oF -- 'optional argument untouched of function Opaque_holder.Opaque_unrelated.+h is never used' regression.out
  optional argument untouched of function Opaque_holder.Opaque_unrelated.+h is never used
  $ grep -m1 -oF -- 'optional argument partial of function Partial_context.Partial_supplied_arg.+g is always supplied (1 calls)' regression.out
  optional argument partial of function Partial_context.Partial_supplied_arg.+g is always supplied (1 calls)
  $ grep -m1 -oF -- 'optional argument partial of function Partial_context.Passed_supplied_arg.+g is always supplied (1 calls)' regression.out
  optional argument partial of function Partial_context.Passed_supplied_arg.+g is always supplied (1 calls)
  $ grep -m1 -oF -- 'optional argument partial of function Partial_context.Packed_partial_arg.+g is always supplied (1 calls)' regression.out
  optional argument partial of function Partial_context.Packed_partial_arg.+g is always supplied (1 calls)
  $ grep -m1 -oF -- 'optional argument partial of function Partial_context.Unit_partial_arg.+g is always supplied (1 calls)' regression.out
  optional argument partial of function Partial_context.Unit_partial_arg.+g is always supplied (1 calls)
  $ grep -m1 -oF -- 'optional argument partial of function Partial_context.Forwarded_supplied_arg.+g is always supplied (1 calls)' regression.out
  optional argument partial of function Partial_context.Forwarded_supplied_arg.+g is always supplied (1 calls)
  $ grep -m1 -oF -- 'optional argument partial of function Foreign_supplied_arg.+g is always supplied (1 calls)' regression.out
  optional argument partial of function Foreign_supplied_arg.+g is always supplied (1 calls)
  $ grep -m1 -oF -- 'optional argument partial of function Partial_context.Partial_omitted_arg.+g is never used' regression.out
  optional argument partial of function Partial_context.Partial_omitted_arg.+g is never used
  $ grep -m1 -oF -- 'optional argument partial of function Partial_context.Passed_omitted_arg.+g is never used' regression.out
  optional argument partial of function Partial_context.Passed_omitted_arg.+g is never used
  $ grep -m1 -oF -- 'optional argument partial of function Partial_context.Forwarded_omitted_arg.+g is never used' regression.out
  optional argument partial of function Partial_context.Forwarded_omitted_arg.+g is never used
  $ grep -m1 -oF -- 'optional argument partial of function Foreign_omitted_arg.+g is never used' regression.out
  optional argument partial of function Foreign_omitted_arg.+g is never used

Escaping holders also expose functors defined outside their lexical range through module aliases and includes.

  $ grep -m1 -oF -- 'optional argument alias of function Escaped_alias_arg.+g is always supplied' regression.out
  optional argument alias of function Escaped_alias_arg.+g is always supplied
  $ grep -m1 -oF -- 'Escaped_alias_arg.+g is never used' regression.out
  [1]
  $ grep -m1 -oF -- 'optional argument included of function Escaped_include_arg.+g is always supplied' regression.out
  optional argument included of function Escaped_include_arg.+g is always supplied
  $ grep -m1 -oF -- 'Escaped_include_arg.+g is never used' regression.out
  [1]
  $ grep -m1 -oF -- 'Live Value +Escaped_coercion.Escaped_only.Possible_arg.+needed' regression.out
  Live Value +Escaped_coercion.Escaped_only.Possible_arg.+needed
  $ grep -m1 -oF -- 'Dead Value +Escaped_coercion.Escaped_only.Possible_arg.+needed' regression.out
  [1]
  $ grep -m1 -oF -- 'Dead Value +Escaped_coercion.Escaped_only.Possible_arg.+unused' regression.out
  Dead Value +Escaped_coercion.Escaped_only.Possible_arg.+unused
  $ grep -m1 -oF -- 'Live Value +Escaped_coercion.Known_and_escaped.Possible_arg.+needed' regression.out
  Live Value +Escaped_coercion.Known_and_escaped.Possible_arg.+needed
  $ grep -m1 -oF -- 'Dead Value +Escaped_coercion.Known_and_escaped.Possible_arg.+needed' regression.out
  [1]
  $ grep -m1 -oF -- 'Dead Value +Escaped_coercion.Known_and_escaped.Possible_arg.+unused' regression.out
  Dead Value +Escaped_coercion.Known_and_escaped.Possible_arg.+unused
  $ grep -m1 -oF -- 'Dead Value +Escaped_coercion.Never_applied.Unrelated_arg.+needed' regression.out
  Dead Value +Escaped_coercion.Never_applied.Unrelated_arg.+needed
  $ grep -m1 -oF -- 'Live Value +Escaped_coercion.Known_only.Known_arg.+needed' regression.out
  Live Value +Escaped_coercion.Known_only.Known_arg.+needed
  $ grep -m1 -oF -- 'Dead Value +Escaped_coercion.Known_only.Unrelated_arg.+needed' regression.out
  Dead Value +Escaped_coercion.Known_only.Unrelated_arg.+needed
  $ grep -m1 -oF -- 'Live Value +Escaped_coercion.Nested_stored.Possible_arg.N.+needed' regression.out
  Live Value +Escaped_coercion.Nested_stored.Possible_arg.N.+needed
  $ grep -m1 -oF -- 'Dead Value +Escaped_coercion.Nested_stored.Possible_arg.N.+unused' regression.out
  Dead Value +Escaped_coercion.Nested_stored.Possible_arg.N.+unused
  $ grep -m1 -oF -- 'optional argument mixed of function Mixed_holders.Known_arg.+g is always supplied (1 calls)' regression.out
  optional argument mixed of function Mixed_holders.Known_arg.+g is always supplied (1 calls)
  $ grep -m1 -oF -- 'optional argument mixed of function Mixed_holders.Anonymous_arg.+g is always supplied (1 calls)' regression.out
  optional argument mixed of function Mixed_holders.Anonymous_arg.+g is always supplied (1 calls)
  $ grep -m1 -oF -- 'optional argument mixed of function Mixed_holders.Included_arg.+g is always supplied (1 calls)' regression.out
  optional argument mixed of function Mixed_holders.Included_arg.+g is always supplied (1 calls)
  $ grep -m1 -oF -- 'optional argument mixed of function Mixed_holders.Omitted_arg.+g is never used' regression.out
  optional argument mixed of function Mixed_holders.Omitted_arg.+g is never used
  $ grep -m1 -oF -- 'optional argument mixed of function Mixed_holders.Unrelated_arg.+g is never used' regression.out
  optional argument mixed of function Mixed_holders.Unrelated_arg.+g is never used
  $ grep -m1 -oF -- 'Live Value +Review_round.Partial_result.F.+run' regression.out
  Live Value +Review_round.Partial_result.F.+run
  $ grep -m1 -oF -- 'Dead Value +Review_round.Partial_result.F.+run' regression.out
  [1]
  $ grep -m1 -oF -- 'Dead Value +Review_round.Partial_result.F.+unused' regression.out
  Dead Value +Review_round.Partial_result.F.+unused
  $ grep -m1 -oF -- 'optional argument result of function Partial_result.F.+run is always supplied (2 calls)' regression.out
  optional argument result of function Partial_result.F.+run is always supplied (2 calls)
  $ grep -m1 -oF -- 'optional argument local_alias of function Local_alias.Arg.+g is always supplied (1 calls)' regression.out
  optional argument local_alias of function Local_alias.Arg.+g is always supplied (1 calls)
  $ grep -m1 -oF -- 'optional argument recursive_alias of function Recursive_alias.Arg.+g is always supplied (1 calls)' regression.out
  optional argument recursive_alias of function Recursive_alias.Arg.+g is always supplied (1 calls)
  $ grep -m1 -oF -- 'optional argument nested_arg of function Known.N.+g is always supplied (1 calls)' regression.out
  optional argument nested_arg of function Known.N.+g is always supplied (1 calls)
  $ grep -m1 -oF -- 'optional argument nested_arg of function B.N.+g is always supplied (1 calls)' regression.out
  optional argument nested_arg of function B.N.+g is always supplied (1 calls)
  $ grep -m1 -oF -- 'optional argument nested_arg of function C.Actual.+g is always supplied (1 calls)' regression.out
  optional argument nested_arg of function C.Actual.+g is always supplied (1 calls)
  $ grep -m1 -oF -- 'optional argument nested_arg of function D.N.+g is always supplied (1 calls)' regression.out
  optional argument nested_arg of function D.N.+g is always supplied (1 calls)
  $ grep -m1 -oF -- 'optional argument nested_arg of function Packed_arg.N.+g is always supplied (1 calls)' regression.out
  optional argument nested_arg of function Packed_arg.N.+g is always supplied (1 calls)
  $ grep -m1 -oF -- 'optional argument nested_arg of function Unrelated.N.+g is never used' regression.out
  optional argument nested_arg of function Unrelated.N.+g is never used
  $ grep -m1 -oF -- 'optional argument foreign_nested of function Actual.N.+g is always supplied (1 calls)' regression.out
  optional argument foreign_nested of function Actual.N.+g is always supplied (1 calls)
  $ grep -m1 -oF -- 'optional argument foreign_nested of function Unrelated.N.+g is never used' regression.out
  optional argument foreign_nested of function Unrelated.N.+g is never used

The matching .cmti supplies the digest, while the sibling .cmt supplies the shape needed to distinguish implementations of Dup_sig.S.

  $ grep -m1 -oF -- 'Live Value +Dup_shape.A_chosen.+f' all.out
  Live Value +Dup_shape.A_chosen.+f
  $ grep -m1 -oF -- 'Live Value +Dup_shape.A_unused.+f' all.out
  [1]
  $ grep -m1 -oF -- 'Dead Value +Dup_shape.A_unused.+f' all.out
  Dead Value +Dup_shape.A_unused.+f
  $ grep -m1 -oF -- 'Dead Value +Dup_shape.B_unused.+f' all.out
  Dead Value +Dup_shape.B_unused.+f
