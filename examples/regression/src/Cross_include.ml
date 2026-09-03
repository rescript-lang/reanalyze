(* A functor whose result obtains a nested functor through an include of a
   module local to this file; applied from another file. *)
module Helpers = struct
  module Inner (B : Shared_signature.O) = struct
    let run () = B.g ~x:1 ()
  end
end

module Outer_x (A : Shared_signature.S) = struct
  let _ = A.f
  include Helpers
end
