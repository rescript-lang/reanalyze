module type Arg = sig val g : ?included:int -> unit -> int end
module type Holder_t = sig
  module Inner (M : Arg) : sig val run : unit -> int end
end
module Holder = struct
  module Inner (M : Arg) = struct let run () = M.g ~included:1 () end
end
let packed = (module Holder : Holder_t)
include (val packed : Holder_t)
module Unpacked_include_arg : Arg = struct let g ?(included = 0) () = included end
module Applied = Inner (Unpacked_include_arg)
let run () = ignore (Applied.run ())
