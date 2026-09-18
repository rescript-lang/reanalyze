module Repacked = struct
  module type S = sig val g : ?repacked:int -> unit -> int end
  module type FT = functor (M : S) -> sig val run : unit -> int end
  module Make (M : S) = struct let run () = M.g ~repacked:1 () end
  let first = (module Make : FT)
  module First = (val first : FT)
  let second = (module First : FT)
  module Second = (val second : FT)
  let third = (module Second : FT)
  module Third = (val third : FT)
  module Repacked_arg : S = struct let g ?(repacked = 0) () = repacked end
  module Repacked_unused : S = struct let g ?(repacked = 0) () = repacked end
  module Applied = Third (Repacked_arg)
  let run () = ignore (Applied.run ()); ignore (Repacked_unused.g ())
end

module Projected = struct
  module type S = sig val g : ?projected:int -> unit -> int end
  module type FT = functor (M : S) -> sig val run : unit -> int end
  module type Holder_t = sig module Inner : FT end
  module Use (H : Holder_t) (M : S) = struct
    module Applied = H.Inner (M)
    let run = Applied.run
  end
  module Forward (H : Holder_t) (M : S) = Use (H) (M)
  module Holder = struct
    module Inner (M : S) = struct let run () = M.g ~projected:1 () end
  end
  module Projected_arg : S = struct let g ?(projected = 0) () = projected end
  module Projected_unused : S = struct let g ?(projected = 0) () = projected end
  module Applied = Forward (Holder) (Projected_arg)
  let run () = ignore (Applied.run ()); ignore (Projected_unused.g ())
end

module Opaque_holder = struct
  module type S = sig val g : ?opaque:int -> unit -> int end
  module type FT = functor (M : S) -> sig val run : unit -> int end
  module type Holder_t = sig module Inner : FT end
  module Use (H : Holder_t) (M : S) = struct
    module Applied = H.Inner (M)
    let run = Applied.run
  end
  module Holder = struct
    module Inner (M : S) = struct let run () = M.g ~opaque:1 () end
  end
  let packed = (module Holder : Holder_t)
  module Opaque_arg : S = struct let g ?(opaque = 0) () = opaque end
  module Applied = Use ((val packed : Holder_t)) (Opaque_arg)
  module type Other = sig val h : ?untouched:int -> unit -> int end
  module Never_applied (M : Other) = struct let run () = M.h ~untouched:1 () end
  module Opaque_unrelated : Other = struct let h ?(untouched = 0) () = untouched end
  let run () = ignore (Applied.run ()); ignore (Opaque_unrelated.h ())
end

module Partial_context = struct
  module type S = sig val g : ?partial:int -> unit -> int end
  module type FT = functor (M : S) -> sig val run : unit -> int end
  module Supplied (M : S) = struct let run () = M.g ~partial:1 () end
  module Omitted (M : S) = struct let run () = M.g () end
  module Outer (F : FT) (M : S) = F (M)
  module Partial_supplied_arg : S = struct let g ?(partial = 0) () = partial end
  module Partial_omitted_arg : S = struct let g ?(partial = 0) () = partial end
  module Supply = Outer (Supplied)
  module Omit = Outer (Omitted)
  module Applied_supply = Supply (Partial_supplied_arg)
  module Applied_omit = Omit (Partial_omitted_arg)
  module Invoke (F : FT) (M : S) = F (M)
  module Passed_supplied_arg : S = struct let g ?(partial = 0) () = partial end
  module Passed_omitted_arg : S = struct let g ?(partial = 0) () = partial end
  module Passed_supply = Invoke (Supply) (Passed_supplied_arg)
  module Passed_omit = Invoke (Omit) (Passed_omitted_arg)
  let packed = (module Supply : FT)
  module Repacked = (val packed : FT)
  module Packed_partial_arg : S = struct let g ?(partial = 0) () = partial end
  module Packed_supply = Repacked (Packed_partial_arg)
  module With_unit (F : FT) () (M : S) = F (M)
  module Unit_prefix = With_unit (Supplied)
  module Unit_middle = Unit_prefix ()
  module Unit_partial_arg : S = struct let g ?(partial = 0) () = partial end
  module Unit_supply = Unit_middle (Unit_partial_arg)
  module type Higher = functor (F : FT) -> FT
  module Forward_partial (F : Higher) (G : FT) (M : S) = struct
    module Half = F (G)
    module Applied = Invoke (Half) (M)
    let run = Applied.run
  end
  module Forwarded_supplied_arg : S = struct let g ?(partial = 0) () = partial end
  module Forwarded_omitted_arg : S = struct let g ?(partial = 0) () = partial end
  module Forwarded_supply = Forward_partial (Outer) (Supplied) (Forwarded_supplied_arg)
  module Forwarded_omit = Forward_partial (Outer) (Omitted) (Forwarded_omitted_arg)
  let run () =
    ignore (Applied_supply.run ());
    ignore (Applied_omit.run ());
    ignore (Passed_supply.run ());
    ignore (Passed_omit.run ());
    ignore (Packed_supply.run ());
    ignore (Unit_supply.run ());
    ignore (Forwarded_supply.run ());
    ignore (Forwarded_omit.run ())
end

let run () =
  Repacked.run ();
  Projected.run ();
  Opaque_holder.run ();
  Partial_context.run ()
