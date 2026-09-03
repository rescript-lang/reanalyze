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
