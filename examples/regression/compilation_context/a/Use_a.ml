module Arg : Shared.S = struct
  let g ?(context = 0) () = context
end

module Applied = Shared.Apply (Arg)

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
