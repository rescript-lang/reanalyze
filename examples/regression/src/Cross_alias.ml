(* An alias of a functor defined in another file, applied from a third. *)
module G = Shared_signature_arg.Apply_opt

(* A partial application bound in this file, completed from another. *)
module GP = Shared_signature_arg.Apply2 (Shared_signature_arg.Chosen)

module Outer_y (X : Shared_signature.S) = struct
  let _ = X.f
  include Cross_include.Helpers2
end
