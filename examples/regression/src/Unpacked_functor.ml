module type Arg = sig val g : ?x:int -> unit -> int end
module type FT = functor (M : Arg) -> sig val run : unit -> int end

module Impl (M : Arg) = struct let run () = M.g ~x:1 () end
let packed = (module Impl : FT)
module G = (val packed : FT)
module Alias = G

module type Nested_arg = sig val g : ?nested:int -> unit -> int end
module type Holder_t = sig
  module Inner (M : Nested_arg) : sig val run : unit -> int end
end
module Holder_impl = struct
  module Inner (M : Nested_arg) = struct let run () = M.g ~nested:1 () end
end
let holder = (module Holder_impl : Holder_t)
module Holder = (val holder : Holder_t)
