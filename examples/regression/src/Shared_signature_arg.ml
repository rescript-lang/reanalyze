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
