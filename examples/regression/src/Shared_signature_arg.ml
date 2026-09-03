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
