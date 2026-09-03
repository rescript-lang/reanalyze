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
