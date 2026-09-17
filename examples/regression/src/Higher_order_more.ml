(* A functor whose body is directly the application of its functor
   parameter, and a higher-order functor from another file applied here to a
   functor from a third file. *)
module Opt_direct_body : Shared_signature.O = struct
  let g ?(x = 0) () = x
end

module Opt_cross_ho : Shared_signature.O = struct
  let g ?(x = 0) () = x
end

module Impl_direct_body (M : Shared_signature.O) = struct
  let run () = M.g ~x:1 ()
end

module Outer_direct (F : Higher_order.Opt_functor) (M : Shared_signature.O) =
  F (M)

module Applied_direct_body = Outer_direct (Impl_direct_body) (Opt_direct_body)

module Applied_cross_ho =
  Cross_alias.Outer_cross_ho (Shared_signature_arg.Impl_third) (Opt_cross_ho)

let run () = ignore (Applied_direct_body.run () + Applied_cross_ho.run ())

(* The functor parameter's type written inline rather than named: the
   passed functor's values, used through the parameter, stay live. *)
module Opt_anon : Shared_signature.O = struct
  let g ?(x = 0) () = x
end

module Impl_anon (M : Shared_signature.O) = struct
  let run () = M.g ~x:1 ()
  let helper () = 1
end

module Outer_anon
    (F : functor (M : Shared_signature.O) -> sig
      val run : unit -> int
    end)
    (M : Shared_signature.O) =
struct
  module A = F (M)

  let run () = A.run ()
end

module Applied_anon = Outer_anon (Impl_anon) (Opt_anon)

let run_anon () = ignore (Applied_anon.run ())

(* Functors reached through something whose applications cannot be seen:
   nested in a module packed as a first-class value, and nested in the
   result of a functor parameter applied in the body. Their calls are
   forwarded conservatively: the arguments must not be reported as never
   supplying the argument. *)
module type P2 = sig
  val k : ?z:int -> unit -> int
end

module type Holder_t = sig
  module Inner : functor (M : P2) -> sig
    val run : unit -> int
  end
end

module Holder = struct
  module Inner (M : P2) = struct
    let run () = M.k ~z:1 ()
  end
end

module P2_esc : P2 = struct
  let k ?(z = 0) () = z
end

let packed_holder = (module Holder : Holder_t)

let apply_holder (module H : Holder_t) =
  let module A = H.Inner (P2_esc) in
  A.run ()

module type P3 = sig
  val q : ?w:int -> unit -> int
end

module type Gi_t = functor (A : Shared_signature.S) -> sig
  module Inner : functor (M : P3) -> sig
    val run : unit -> int
  end
end

module Impl_gi (A : Shared_signature.S) = struct
  module Inner (M : P3) = struct
    let run () = M.q ~w:1 () + A.f ()
  end
end

module P3_esc : P3 = struct
  let q ?(w = 0) () = w
end

module Outer_gi (F : Gi_t) (M : P3) = struct
  module G = F (Shared_signature_arg.Chosen)
  module A = G.Inner (M)

  let run () = A.run ()
end

module Applied_gi = Outer_gi (Impl_gi) (P3_esc)

let run_nested () = ignore (apply_holder packed_holder + Applied_gi.run ())

(* A functor applied directly and also packed into a value that flows
   through a function: the unseen application means its calls are forwarded,
   so the second argument is not reported as never supplying [v]. *)
module type P4 = sig
  val u : ?v:int -> unit -> int
end

module type P4_functor = functor (M : P4) -> sig
  val run : unit -> int
end

module Impl_both (M : P4) = struct
  let run () = M.u ~v:1 ()
end

module P4_a : P4 = struct
  let u ?(v = 0) () = v
end

module P4_b : P4 = struct
  let u ?(v = 0) () = v
end

module Applied_both_a = Impl_both (P4_a)

let packed_both = (module Impl_both : P4_functor)
let through f = f

module Applied_both_b = (val through packed_both : P4_functor) (P4_b)

let run_both () = ignore (Applied_both_a.run () + Applied_both_b.run ())
