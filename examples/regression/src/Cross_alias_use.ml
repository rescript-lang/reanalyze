module Opt_cross : Shared_signature.O = struct
  let g ?(x = 0) () = x
end

module Applied_cross = Cross_alias.G (Opt_cross)

let run () = ignore (Applied_cross.run ())
