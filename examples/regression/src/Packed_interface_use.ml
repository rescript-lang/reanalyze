module Packed_arg : Packed_types.Arg = struct
  let g ?(x = 0) () = x
end

module Outer (F : Packed_types.FT) (M : Packed_types.Arg) = F (M)
module A = Outer ((val Packed_interface.packed : Packed_types.FT)) (Packed_arg)

let run () = ignore (A.run ())
