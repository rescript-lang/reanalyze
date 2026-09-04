(* Higher-order functors: a functor passed as an argument and applied inside
   the body, to a parameter, to a fixed module, to a submodule of a
   parameter, through an alias of the functor parameter, in an [include],
   partially applied beforehand, through two levels, and first-class modules
   as head and as argument. [Opt_none_ho] is called directly only and keeps
   its never-used argument. *)
module type Opt_functor = functor (M : Shared_signature.O) -> sig
  val run : unit -> int
end

module Impl (M : Shared_signature.O) = struct
  let run () = M.g ~x:1 ()
end

module Impl_fixed (M : Shared_signature.O) = struct
  let run () = M.g ~x:1 ()
end

module Impl_sub (M : Shared_signature.O) = struct
  let run () = M.g ~x:1 ()
end

module Impl_alias (M : Shared_signature.O) = struct
  let run () = M.g ~x:1 ()
end

module Impl_incl (M : Shared_signature.O) = struct
  let run () = M.g ~x:1 ()
end

module Impl_partial (A : Shared_signature.S) (M : Shared_signature.O) = struct
  let run () = M.g ~x:1 () + A.f ()
end

module Impl_2 (M : Shared_signature.O) = struct
  let run () = M.g ~x:1 ()
end

module Impl_fc (M : Shared_signature.O) = struct
  let run () = M.g ~x:1 ()
end

module Impl_fca (M : Shared_signature.O) = struct
  let run () = M.g ~x:1 ()
end

module Impl_twice_a (M : Shared_signature.O) = struct
  let run () = M.g ~x:1 ()
end

module Impl_twice_b (M : Shared_signature.O) = struct
  let run () = M.g ~x:1 ()
end

module Opt_ho : Shared_signature.O = struct
  let g ?(x = 0) () = x
end

module Opt_fixed : Shared_signature.O = struct
  let g ?(x = 0) () = x
end

module Opt_sub_holder = struct
  module Sub : Shared_signature.O = struct
    let g ?(x = 0) () = x
  end
end

module Opt_alias_ho : Shared_signature.O = struct
  let g ?(x = 0) () = x
end

module Opt_incl_ho : Shared_signature.O = struct
  let g ?(x = 0) () = x
end

module Opt_partial_ho : Shared_signature.O = struct
  let g ?(x = 0) () = x
end

module Opt_2 : Shared_signature.O = struct
  let g ?(x = 0) () = x
end

module Opt_fc : Shared_signature.O = struct
  let g ?(x = 0) () = x
end

module Opt_fca : Shared_signature.O = struct
  let g ?(x = 0) () = x
end

module Opt_twice : Shared_signature.O = struct
  let g ?(x = 0) () = x
end

module Opt_none_ho : Shared_signature.O = struct
  let g ?(x = 0) () = x
end

module Outer (F : Opt_functor) (M : Shared_signature.O) = struct
  module A = F (M)

  let run () = A.run ()
end

module Applied_ho = Outer (Impl) (Opt_ho)

module Outer_fixed (F : Opt_functor) = struct
  module A = F (Opt_fixed)

  let run () = A.run ()
end

module Applied_fixed = Outer_fixed (Impl_fixed)

module Outer_sub (F : Opt_functor) (H : sig
  module Sub : Shared_signature.O
end) =
struct
  module A = F (H.Sub)

  let run () = A.run ()
end

module Applied_sub = Outer_sub (Impl_sub) (Opt_sub_holder)

module Outer_alias (F : Opt_functor) (M : Shared_signature.O) = struct
  module G = F
  module A = G (M)

  let run () = A.run ()
end

module Applied_alias = Outer_alias (Impl_alias) (Opt_alias_ho)

module Outer_incl (F : Opt_functor) (M : Shared_signature.O) = struct
  include F (M)
end

module Applied_incl = Outer_incl (Impl_incl) (Opt_incl_ho)
module Applied_partial = Outer (Impl_partial (Shared_signature_arg.Chosen)) (Opt_partial_ho)

module Outer2 (F : Opt_functor) (M : Shared_signature.O) = struct
  module A = Outer (F) (M)

  let run () = A.run ()
end

module Applied_2 = Outer2 (Impl_2) (Opt_2)

let impl_fc = (module Impl_fc : Opt_functor)

module Applied_fc = (val impl_fc : Opt_functor) (Opt_fc)

let opt_fca = (module Opt_fca : Shared_signature.O)

module Applied_fca = Impl_fca ((val opt_fca : Shared_signature.O))
module Applied_twice_a = Outer (Impl_twice_a) (Opt_twice)
module Applied_twice_b = Outer (Impl_twice_b) (Opt_twice)

let run () =
  ignore
    (Applied_ho.run () + Applied_fixed.run () + Applied_sub.run ()
   + Applied_alias.run () + Applied_incl.run () + Applied_partial.run ()
   + Applied_2.run () + Applied_fc.run () + Applied_fca.run ()
   + Applied_twice_a.run () + Applied_twice_b.run () + Opt_none_ho.g ())

(* Inline functors returning their parameter, a submodule of it, or a
   functor applied to it: the actual argument is what flows on. [Id_unused]
   is never passed and stays dead; [Opt_id]'s call is credited to it only. *)
module Id_used : Shared_signature.S = struct
  let f () = 70
end

module Id_sub_holder = struct
  module Sub : Shared_signature.S = struct
    let f () = 71
  end
end

module Id_app : Shared_signature.S = struct
  let f () = 72
end

module Id_curried : Shared_signature.S = struct
  let f () = 73
end

module Id_unused : Shared_signature.S = struct
  let f () = 74
end

module Opt_id : Shared_signature.O = struct
  let g ?(x = 0) () = x
end

module Use_s (M : Shared_signature.S) = struct
  let run () = M.f ()
end

module Applied_id = Use_s ((functor (A : Shared_signature.S) -> A) (Id_used))

module Applied_id_sub =
  Use_s
    ((functor (H : sig
        module Sub : Shared_signature.S
      end) -> H.Sub)
       (Id_sub_holder))

module Applied_id_app =
  Use_s
    ((functor (A : Shared_signature.S) -> Shared_signature_arg.Mk_s (A))
       (Id_app))

module Applied_id_curried =
  Use_s
    ((functor (A : Shared_signature.S) (B : Shared_signature.S) -> B)
       (Id_used)
       (Id_curried))

module Applied_opt_id =
  Shared_signature_arg.Use_o ((functor (A : Shared_signature.O) -> A) (Opt_id))

let run_id () =
  ignore
    (Applied_id.run () + Applied_id_sub.run () + Applied_id_app.run ()
   + Applied_id_curried.run () + Applied_opt_id.run ())

(* A functor escaping as a first-class module passed to a function: its
   applications cannot be seen, so its calls are forwarded to every
   implementation of the item, conservatively. [P_esc] must not be reported
   as never supplying [y]. *)
module type P = sig
  val h : ?y:int -> unit -> int
end

module type P_functor = functor (M : P) -> sig
  val run : unit -> int
end

module Impl_esc (M : P) = struct
  let run () = M.h ~y:1 ()
end

module P_esc : P = struct
  let h ?(y = 0) () = y
end

module P_other : P = struct
  let h ?(y = 0) () = y
end

let apply_packed (module F : P_functor) =
  let module A = F (P_esc) in
  A.run ()

let run_esc () = ignore (apply_packed (module Impl_esc) + P_other.h ())
