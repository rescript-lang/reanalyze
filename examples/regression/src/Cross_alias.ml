(* An alias of a functor defined in another file, applied from a third. *)
module G = Shared_signature_arg.Apply_opt

(* A partial application bound in this file, completed from another. *)
module GP = Shared_signature_arg.Apply2 (Shared_signature_arg.Chosen)

module Outer_y (X : Shared_signature.S) = struct
  let _ = X.f
  include Cross_include.Helpers2
end

(* A unit application bound in this file, completed from another. *)
module GU = Shared_signature_arg.F_unit ()

(* A functor applied in another file, as an argument of a further functor. *)
module Mk_cross (A : Shared_signature.S) : Shared_signature.O = struct
  let g ?(x = 0) () = x + A.f ()
end

module Mk_cross_alias = Mk_cross

(* A functor packed as a first-class module, unpacked and applied from
   another file. *)
module Impl_cross_fc (M : Shared_signature.O) = struct
  let run () = M.g ~x:1 ()
end

let packed_cross = (module Impl_cross_fc : Higher_order.Opt_functor)

module Outer_cross_ho (F : Higher_order.Opt_functor) (M : Shared_signature.O) =
struct
  module A = F (M)

  let run () = A.run ()
end

(* Packed by a consumer in another compilation unit: chasing the alias's
   local path requires this unit's resolver. *)
module type Escaped_arg = sig
  val k : ?cross:int -> unit -> int
end

module type Escaped_holder_type = sig
  module Inner : functor (M : Escaped_arg) -> sig
    val run : unit -> int
  end
end

module Escaped_inner (M : Escaped_arg) = struct
  let run () = M.k ~cross:1 ()
end

module Escaped_holder = struct
  module Inner = Escaped_inner
end

module Escaped_alias = Escaped_holder
