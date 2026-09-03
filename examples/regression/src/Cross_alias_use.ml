module Opt_cross : Shared_signature.O = struct
  let g ?(x = 0) () = x
end

module Applied_cross = Cross_alias.G (Opt_cross)

let run () = ignore (Applied_cross.run ())

module Opt_cross_partial : Shared_signature.O = struct
  let g ?(x = 0) () = x
end

module Applied_cross_partial = Cross_alias.GP (Opt_cross_partial)

let run_partial () = ignore (Applied_cross_partial.run ())

module Opt_cross_incl : Shared_signature.O = struct
  let g ?(x = 0) () = x
end

module Applied_outer_x = Cross_include.Outer_x (Shared_signature_arg.Chosen)
module Applied_cross_incl = Applied_outer_x.Inner (Opt_cross_incl)

let run_incl () = ignore (Applied_cross_incl.run ())
