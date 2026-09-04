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

module Opt_y : Shared_signature.O = struct
  let g ?(x = 0) () = x
end

module Applied_outer_y = Cross_alias.Outer_y (Shared_signature_arg.Chosen)
module Applied_y = Applied_outer_y.Inner2 (Opt_y)

let run_y () = ignore (Applied_y.run ())

module Opt_cross_unit : Shared_signature.O = struct
  let g ?(x = 0) () = x
end

module Opt_cross_unit2 : Shared_signature.O = struct
  let g ?(x = 0) () = x
end

module Applied_cross_unit = Cross_alias.GU (Opt_cross_unit)
module Applied_cross_unit2 = Shared_signature_arg.F_unit () (Opt_cross_unit2)

module Applied_app_cross =
  Shared_signature_arg.Use_o (Cross_alias.Mk_cross (Shared_signature_arg.Chosen))

let run_unit () =
  ignore
    (Applied_cross_unit.run () + Applied_cross_unit2.run ()
   + Applied_app_cross.run ())

(* An applied functor aliased in another file. *)
module Applied_app_cross_alias =
  Shared_signature_arg.Use_o
    (Cross_alias.Mk_cross_alias (Shared_signature_arg.Chosen))

let run_alias_app () = ignore (Applied_app_cross_alias.run ())

module Opt_cross_fc : Shared_signature.O = struct
  let g ?(x = 0) () = x
end

module Applied_cross_fc =
  (val Cross_alias.packed_cross : Higher_order.Opt_functor) (Opt_cross_fc)

let run_fc () = ignore (Applied_cross_fc.run ())
