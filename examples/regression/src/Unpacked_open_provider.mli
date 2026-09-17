module type Arg = Unpacked_open_types.Arg
module type Holder_t = Unpacked_open_types.Holder_t
module Holder : Holder_t
val packed : (module Holder_t)
