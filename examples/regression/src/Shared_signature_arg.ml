(* Two modules implement the shared named signature; only [Chosen] is passed
   to a functor. [Ignored.f] must be reported dead. *)
module Chosen : Shared_signature.S = struct
  let f () = 3
end

module Ignored : Shared_signature.S = struct
  let f () = 4
end

module Apply (M : Shared_signature.S) = struct
  let run () = M.f ()
end

module Applied = Apply (Chosen)

(* Same, but the module is used directly from the same file. *)
module Local_used : Shared_signature.S = struct
  let f () = 5
end

module Local_unused : Shared_signature.S = struct
  let f () = 6
end

let run () = ignore (Applied.run () + Local_used.f ())

(* A binding calling both through the parameter and a resolved module: the
   parameter call must still not be forwarded to [Ignored]. *)
module Apply_mixed (M : Shared_signature.S) = struct
  let run () = M.f () + Chosen.f ()
end

module Applied_mixed = Apply_mixed (Chosen)

(* Optional argument supplied only through a functor parameter call: must be
   credited to [Opt_chosen] only, so [Opt_direct]'s [x] stays never used. *)
module Opt_chosen : Shared_signature.O = struct
  let g ?(x = 0) () = x
end

module Opt_direct : Shared_signature.O = struct
  let g ?(x = 0) () = x
end

module Apply_opt (M : Shared_signature.O) = struct
  let run () = M.g ~x:1 ()
end

module Applied_opt = Apply_opt (Opt_chosen)

let run_more () =
  ignore (Applied_mixed.run () + Applied_opt.run () + Opt_direct.g ())

(* Argument wrapped in a constraint: [(Opt_constrained : O)]. *)
module Opt_constrained : Shared_signature.O = struct
  let g ?(x = 0) () = x
end

module Applied_constrained = Apply_opt ((Opt_constrained : Shared_signature.O))

(* Inline functor applied directly. *)
module Opt_inline : Shared_signature.O = struct
  let g ?(x = 0) () = x
end

module Applied_inline =
  (functor (M : Shared_signature.O) -> struct
    let run () = M.g ~x:1 ()
  end)
    (Opt_inline)

(* Constrained argument for liveness: [Ignored2] must stay dead. *)
module Chosen2 : Shared_signature.S = struct
  let f () = 7
end

module Ignored2 : Shared_signature.S = struct
  let f () = 8
end

module Applied_constrained_value = Apply ((Chosen2 : Shared_signature.S))

let run_even_more () =
  ignore
    (Applied_constrained.run () + Applied_inline.run ()
   + Applied_constrained_value.run ())

(* Named functor with a whole-functor signature: the binding expression is a
   constraint around the functor. *)
module Opt_sigfun : Shared_signature.O = struct
  let g ?(x = 0) () = x
end

module Apply_sig : functor (M : Shared_signature.O) -> sig
  val run : unit -> int
end =
functor
  (M : Shared_signature.O)
  ->
  struct
    let run () = M.g ~x:1 ()
  end

module Applied_sig = Apply_sig (Opt_sigfun)

let run_sig () = ignore (Applied_sig.run ())

(* Curried functor, partially applied and named before the second argument. *)
module Opt_partial : Shared_signature.O = struct
  let g ?(x = 0) () = x
end

module Apply2 (A : Shared_signature.S) (B : Shared_signature.O) = struct
  let run () = A.f () + B.g ~x:1 ()
end

module Apply2_partial = Apply2 (Chosen)
module Applied_partial = Apply2_partial (Opt_partial)

(* Functor bound with [let module]. *)
module Opt_letmodule : Shared_signature.O = struct
  let g ?(x = 0) () = x
end

let run_local () =
  let module Apply_local (M : Shared_signature.O) = struct
    let run () = M.g ~x:1 ()
  end in
  let module Applied_local = Apply_local (Opt_letmodule) in
  Applied_local.run ()

let run_partial () = ignore (Applied_partial.run () + run_local ())

(* Alias of the parameter inside the body: [N.g] is a parameter call. *)
module Opt_alias : Shared_signature.O = struct
  let g ?(x = 0) () = x
end

module Opt_alias_other : Shared_signature.O = struct
  let g ?(x = 0) () = x
end

module Apply_alias (M : Shared_signature.O) = struct
  module N = M

  let run () = N.g ~x:1 ()
end

module Applied_alias = Apply_alias (Opt_alias)

(* Recursive functor. *)
module Opt_rec : Shared_signature.O = struct
  let g ?(x = 0) () = x
end

module rec Apply_rec : functor (M : Shared_signature.O) -> sig
  val run : unit -> int
end =
functor
  (M : Shared_signature.O)
  ->
  struct
    let run () = M.g ~x:1 ()
  end

module Applied_rec = Apply_rec (Opt_rec)

let run_alias () =
  ignore (Applied_alias.run () + Applied_rec.run () + Opt_alias_other.g ())

(* An identifier through a functor application, [F(X).t]: must not crash the
   occurrence resolver. *)
module Set_of_ints = Set.Make (Int)

let _apply_ident : Set.Make(Int).t = Set_of_ints.empty

(* Argument constrained by an alias of the named module type. *)
module type S_alias = Shared_signature.S

module Chosen3 : Shared_signature.S = struct
  let f () = 9
end

module Ignored3 : Shared_signature.S = struct
  let f () = 10
end

module Applied_alias_mt = Apply ((Chosen3 : S_alias))

(* A functor forwarding its parameter to another functor. *)
module Outer (M : Shared_signature.S) = Apply (M)

module Chosen4 : Shared_signature.S = struct
  let f () = 11
end

module Ignored4 : Shared_signature.S = struct
  let f () = 12
end

module Applied_outer = Outer (Chosen4)

module Outer_opt (M : Shared_signature.O) = Apply_opt (M)

module Opt_outer : Shared_signature.O = struct
  let g ?(x = 0) () = x
end

module Applied_outer_opt = Outer_opt (Opt_outer)

(* [include M] then an unqualified call to an included member. *)
module Apply_incl (M : Shared_signature.O) = struct
  include M

  let run () = g ~x:1 ()
end

module Opt_incl : Shared_signature.O = struct
  let g ?(x = 0) () = x
end

module Opt_incl_other : Shared_signature.O = struct
  let g ?(x = 0) () = x
end

module Applied_incl = Apply_incl (Opt_incl)

let run_forwarded () =
  ignore
    (Applied_alias_mt.run () + Applied_outer.run () + Applied_outer_opt.run ()
   + Applied_incl.run () + Opt_incl_other.g ())

(* [let module G = F in G (A)]: the alias stands for the functor. *)
module Opt_letalias : Shared_signature.O = struct
  let g ?(x = 0) () = x
end

let run_letalias () =
  let module G = Apply_opt in
  let module Applied = G (Opt_letalias) in
  Applied.run ()

(* Module type alias rooted at a module of this file, and a module type
   shadowing a same-named one: resolution must follow identity, not names. *)
module type T = sig
  val f : unit -> int
end

module Inner = struct
  module type T = sig
    val h : unit -> int
  end
end

module type T_alias = Inner.T

module Use_t : Inner.T = struct
  let h () = 3
end

module Apply_h (M : Inner.T) = struct
  let run () = M.h ()
end

module Applied_h = Apply_h ((Use_t : T_alias))

module Shadow = struct
  module type T = sig
    val k : unit -> int
  end

  module type T_alias3 = T

  module Use3 : T = struct
    let k () = 4
  end

  module Apply_k (M : T) = struct
    let run () = M.k ()
  end

  module Applied3 = Apply_k ((Use3 : T_alias3))
end

let run_shadow () =
  ignore (run_letalias () + Applied_h.run () + Shadow.Applied3.run ())

(* A nested module in the parameter's signature, constrained by a named
   module type: [M.N.g] must be credited to the argument's [N.g]. *)
module type With_nested = sig
  module N : Shared_signature.O
end

module Nested_arg : With_nested = struct
  module N = struct
    let g ?(x = 0) () = x
  end
end

module Nested_other : With_nested = struct
  module N = struct
    let g ?(x = 0) () = x
  end
end

module Apply_nested (M : With_nested) = struct
  let run () = M.N.g ~x:1 ()
end

module Applied_nested = Apply_nested (Nested_arg)

let run_nested () = ignore (Applied_nested.run () + Nested_other.N.g ())


(* A parameter forwarded through ten functors. *)
module Opt_chain : Shared_signature.O = struct
  let g ?(x = 0) () = x
end

module Chain0 (M : Shared_signature.O) = struct
  let run () = M.g ~x:1 ()
end

module Chain1 (M : Shared_signature.O) = Chain0 (M)
module Chain2 (M : Shared_signature.O) = Chain1 (M)
module Chain3 (M : Shared_signature.O) = Chain2 (M)
module Chain4 (M : Shared_signature.O) = Chain3 (M)
module Chain5 (M : Shared_signature.O) = Chain4 (M)
module Chain6 (M : Shared_signature.O) = Chain5 (M)
module Chain7 (M : Shared_signature.O) = Chain6 (M)
module Chain8 (M : Shared_signature.O) = Chain7 (M)
module Chain9 (M : Shared_signature.O) = Chain8 (M)
module Chain10 (M : Shared_signature.O) = Chain9 (M)

module Applied_chain = Chain10 (Opt_chain)

(* Modules defined inside a functor body, one applied, one not. *)
module Apply_in_body (X : sig end) = struct
  module Chosen_in : Shared_signature.S = struct
    let f () = 20
  end

  module Ignored_in : Shared_signature.S = struct
    let f () = 21
  end

  module Applied_in = Apply (Chosen_in)

  let run () = Applied_in.run ()
end

module Applied_body = Apply_in_body (struct end)

let run_chain () = ignore (Applied_chain.run () + Applied_body.run ())

(* [let module G = F (A) in G (B)]: a local partial application. *)
module Opt_letpartial : Shared_signature.O = struct
  let g ?(x = 0) () = x
end

let run_letpartial () =
  let module G = Apply2 (Chosen) in
  let module Applied = G (Opt_letpartial) in
  Applied.run ()

let run_local_partial () = ignore (run_letpartial ())


(* A functor reached through nine aliases. *)
module Opt_alias9 : Shared_signature.O = struct
  let g ?(x = 0) () = x
end

module Alias1 = Apply_opt
module Alias2 = Alias1
module Alias3 = Alias2
module Alias4 = Alias3
module Alias5 = Alias4
module Alias6 = Alias5
module Alias7 = Alias6
module Alias8 = Alias7
module Alias9 = Alias8

module Applied_alias9 = Alias9 (Opt_alias9)

let run_alias9 () = ignore (Applied_alias9.run ())

(* A nested functor applied through an extended path: [Outer_f (A).Inner (B)]. *)
module Opt_ext : Shared_signature.O = struct
  let g ?(x = 0) () = x
end

module Outer_f (A : Shared_signature.S) = struct
  module Inner (B : Shared_signature.O) = struct
    let run () = A.f () + B.g ~x:1 ()
  end
end

module Applied_outer_f = Outer_f (Chosen)
module Applied_ext = Applied_outer_f.Inner (Opt_ext)

(* A recursive module binding aliasing a functor. *)
module Opt_rec_alias : Shared_signature.O = struct
  let g ?(x = 0) () = x
end

module rec Rec_alias : functor (M : Shared_signature.O) -> sig
  val run : unit -> int
end =
  Apply_opt

module Applied_rec_alias = Rec_alias (Opt_rec_alias)

let run_ext () = ignore (Applied_ext.run () + Applied_rec_alias.run ())

(* A recursive alias of the parameter inside the body. *)
module Opt_recalias : Shared_signature.O = struct
  let g ?(x = 0) () = x
end

module Opt_recalias_other : Shared_signature.O = struct
  let g ?(x = 0) () = x
end

module Apply_recalias (M : Shared_signature.O) = struct
  module rec N : Shared_signature.O = M

  let run () = N.g ~x:1 ()
end

module Applied_recalias = Apply_recalias (Opt_recalias)

let run_shadow_rec () =
  ignore (Applied_recalias.run () + Opt_recalias_other.g ())

(* A nested functor obtained through [include] in the functor's body. *)
module Opt_incl_f : Shared_signature.O = struct
  let g ?(x = 0) () = x
end

module Outer_i (A : Shared_signature.S) = struct
  include (struct
    module Inner (B : Shared_signature.O) = struct
      let run () = A.f () + B.g ~x:1 ()
    end
  end)
end

module Applied_outer_i = Outer_i (Chosen)
module Applied_incl_f = Applied_outer_i.Inner (Opt_incl_f)

let run_incl_f () = ignore (Applied_incl_f.run ())

(* A forward alias inside a recursive group. *)
module Opt_rec_chain : Shared_signature.O = struct
  let g ?(x = 0) () = x
end

module type Opt_functor = functor (M : Shared_signature.O) -> sig
  val run : unit -> int
end

module rec Rec_g : Opt_functor = Rec_h
and Rec_h : Opt_functor = Apply_opt

module Applied_rec_chain = Rec_g (Opt_rec_chain)

let run_rec_chain () = ignore (Applied_rec_chain.run ())

(* A module type rooted at a functor application: [Outer_mt (Chosen).SM]. *)
module Outer_mt (A : Shared_signature.S) = struct
  let _ = A.f

  module type SM = sig
    val f : unit -> int
  end
end

module type S_app = Outer_mt(Chosen).SM

module Apply_mt (M : S_app) = struct
  let run () = M.f ()
end

module Used_mt : S_app = struct
  let f () = 30
end

module Unused_mt : S_app = struct
  let f () = 31
end

module Applied_mt = Apply_mt ((Used_mt : S_app))

let run_mt () = ignore (Applied_mt.run ())

(* Module types rooted at a functor parameter: [M.T], [M.Sub.T], and
   [Outer_mt (M).SM] with [M] the parameter. *)
module type Has_t = sig
  module type T = sig
    val f : unit -> int
  end

  module Sub : sig
    module type T2 = sig
      val h : unit -> int
    end
  end
end

module Apply_pt (M : Has_t) = struct
  module type T_alias = M.T
  module type T2_alias = M.Sub.T2

  module Use_p : T_alias = struct
    let f () = 40
  end

  module Unused_p : T_alias = struct
    let f () = 41
  end

  module Use_p2 : T2_alias = struct
    let h () = 42
  end

  module Apply_t (X : T_alias) = struct
    let run () = X.f ()
  end

  module Apply_t2 (X : T2_alias) = struct
    let run () = X.h ()
  end

  module Applied_t = Apply_t ((Use_p : T_alias))
  module Applied_t2 = Apply_t2 ((Use_p2 : T2_alias))

  let run () = Applied_t.run () + Applied_t2.run ()
end

module Applied_pt = Apply_pt (struct
  module type T = sig
    val f : unit -> int
  end

  module Sub = struct
    module type T2 = sig
      val h : unit -> int
    end
  end
end)

module Apply_app (M : Shared_signature.S) = struct
  module type T_app = Outer_mt(M).SM

  module Use_a : T_app = struct
    let f () = 43
  end

  module Unused_a : T_app = struct
    let f () = 44
  end

  module Apply_a (X : T_app) = struct
    let run () = X.f ()
  end

  module Applied_a = Apply_a ((Use_a : T_app))

  let run () = Applied_a.run ()
end

module Applied_app = Apply_app (Chosen)

let run_param_mt () = ignore (Applied_pt.run () + Applied_app.run ())

(* Module types through a parameter alias and through [include] of the
   parameter. *)
module Apply_pt2 (M : Has_t) = struct
  module N = M
  module type T_via_alias = N.T

  include M
  module type T_via_include = T

  module Use_alias_mt : T_via_alias = struct
    let f () = 45
  end

  module Use_include_mt : T_via_include = struct
    let f () = 46
  end

  module Apply_ta (X : T_via_alias) = struct
    let run () = X.f ()
  end

  module Apply_ti (X : T_via_include) = struct
    let run () = X.f ()
  end

  module Applied_ta = Apply_ta ((Use_alias_mt : T_via_alias))
  module Applied_ti = Apply_ti ((Use_include_mt : T_via_include))

  let run () = Applied_ta.run () + Applied_ti.run ()
end

module Applied_pt2 = Apply_pt2 (struct
  module type T = sig
    val f : unit -> int
  end

  module Sub = struct
    module type T2 = sig
      val h : unit -> int
    end
  end
end)

let run_param_mt2 () = ignore (Applied_pt2.run ())

(* Module types through an aliased or applied member of an applied functor's
   result: [Outer_h (Chosen).Alias.T] and [Outer_h (Chosen).Applied_inner.T]. *)
module Outer_h (A : Shared_signature.S) = struct
  let _ = A.f

  module Holder = struct
    module type T = sig
      val f : unit -> int
    end
  end

  module Alias = Holder

  module Inner_f (X : Shared_signature.S) = struct
    module type T = sig
      val k : unit -> int
    end
  end

  module Applied_inner = Inner_f (A)
end

module type U_alias = Outer_h(Chosen).Alias.T
module type U_applied = Outer_h(Chosen).Applied_inner.T

module Use_u : U_alias = struct
  let f () = 47
end

module Use_u2 : U_applied = struct
  let k () = 48
end

module Apply_u (X : U_alias) = struct
  let run () = X.f ()
end

module Apply_u2 (X : U_applied) = struct
  let run () = X.k ()
end

module Applied_u = Apply_u ((Use_u : U_alias))
module Applied_u2 = Apply_u2 ((Use_u2 : U_applied))

let run_u () = ignore (Applied_u.run () + Applied_u2.run ())

(* A forward alias of the parameter inside a recursive group. *)
module Opt_recfwd : Shared_signature.O = struct
  let g ?(x = 0) () = x
end

module Opt_recfwd_other : Shared_signature.O = struct
  let g ?(x = 0) () = x
end

module Apply_recfwd (M : Shared_signature.O) = struct
  module rec G : Shared_signature.O = H
  and H : Shared_signature.O = M

  let run () = G.g ~x:1 ()
end

module Applied_recfwd = Apply_recfwd (Opt_recfwd)

let run_recfwd () = ignore (Applied_recfwd.run () + Opt_recfwd_other.g ())
