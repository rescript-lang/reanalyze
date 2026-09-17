module type Arg = Unpacked_open_provider.Arg
module type Holder_t = Unpacked_open_provider.Holder_t
let packed = (module Unpacked_open_provider.Holder : Holder_t)

module Direct = struct
  open (val packed : Holder_t)
  module Open_arg : Arg = struct let g ?(opened = 0) () = opened end
  module Applied = Inner (Open_arg)
  let run () = ignore (Applied.run ())
end

module Local = struct
  module Local_open_arg : Arg = struct let g ?(opened = 0) () = opened end
  let run () =
    let open (val packed : Holder_t) in
    let module Applied = Inner (Local_open_arg) in
    ignore (Applied.run ())
end

module Open_struct = struct
  open struct module H = (val packed : Holder_t) end
  module Open_struct_arg : Arg = struct let g ?(opened = 0) () = opened end
  module Applied = H.Inner (Open_struct_arg)
  let run () = ignore (Applied.run ())
end

module Include_struct = struct
  include struct module H = (val packed : Holder_t) end
  module Include_struct_arg : Arg = struct let g ?(opened = 0) () = opened end
  module Applied = H.Inner (Include_struct_arg)
  let run () = ignore (Applied.run ())
end

module Cross_unit = struct
  open (val Unpacked_open_provider.packed : Holder_t)
  module Cross_open_arg : Arg = struct let g ?(opened = 0) () = opened end
  module Applied = Inner (Cross_open_arg)
  let run () = ignore (Applied.run ())
end

module Unrelated = struct
  module type Arg = sig val g : ?unrelated:int -> unit -> int end
  module Never_applied (M : Arg) = struct let run () = M.g ~unrelated:1 () end
  module Unrelated_arg : Arg = struct let g ?(unrelated = 0) () = unrelated end
  let run () = ignore (Unrelated_arg.g ())
end

let run () =
  Direct.run ();
  Local.run ();
  Open_struct.run ();
  Include_struct.run ();
  Cross_unit.run ();
  Unrelated.run ()
