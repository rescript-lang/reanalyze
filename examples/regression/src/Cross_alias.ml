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
