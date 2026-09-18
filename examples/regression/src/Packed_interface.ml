module Impl (M : Packed_types.Arg) = struct
  let run () = M.g ~x:1 ()
end

let packed = (module Impl : Packed_types.FT)
