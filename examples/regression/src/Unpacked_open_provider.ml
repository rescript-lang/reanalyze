module type Arg = Unpacked_open_types.Arg
module type Holder_t = Unpacked_open_types.Holder_t
module Holder = struct
  module Inner (M : Arg) = struct let run () = M.g ~opened:1 () end
end
let packed = (module Holder : Holder_t)
