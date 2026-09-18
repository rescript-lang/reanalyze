module Arg : Shared.S = struct
  let g ?(context = 0) () = context
end

module Applied = Shared.Apply (Arg)

module Relayed_arg : Shared.S = struct
  let g ?(context = 0) () = context
end

module Relayed = Relay.Apply (Relayed_arg)

let () = ignore (Relayed.run ())
let () = ignore (Applied.run ())

module Partial_arg : Shared.S = struct
  let g ?(context = 0) () = context
end

module Partial = Shared.Alias (Partial_arg)

module Packed_arg : Shared.S = struct
  let g ?(context = 0) () = context
end

module Unpacked = (val Shared.packed : Shared.FT)
module Packed = Unpacked (Packed_arg)

let () =
  ignore (Partial.run ());
  ignore (Packed.run ())
