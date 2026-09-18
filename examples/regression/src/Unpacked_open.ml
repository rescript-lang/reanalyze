module type Arg = Unpacked_open_provider.Arg
module type Holder_t = Unpacked_open_provider.Holder_t

(* Separate signatures and holders keep one case's escape from satisfying
   another case's assertions. *)
module Direct = struct
  module type Arg = sig val g : ?opened:int -> unit -> int end
  module type Holder_t = sig module Inner (M : Arg) : sig val run : unit -> int end end
  module Holder = struct
    module Inner (M : Arg) = struct let run () = M.g ~opened:1 () end
  end
  let packed = (module Holder : Holder_t)
  open (val packed : Holder_t)
  module Open_arg : Arg = struct let g ?(opened = 0) () = opened end
  module Applied = Inner (Open_arg)
  let run () = ignore (Applied.run ())
end

module Local = struct
  module type Arg = sig val g : ?opened:int -> unit -> int end
  module type Holder_t = sig module Inner (M : Arg) : sig val run : unit -> int end end
  module Holder = struct
    module Inner (M : Arg) = struct let run () = M.g ~opened:1 () end
  end
  let packed = (module Holder : Holder_t)
  module Local_open_arg : Arg = struct let g ?(opened = 0) () = opened end
  let run () =
    let open (val packed : Holder_t) in
    let module Applied = Inner (Local_open_arg) in
    ignore (Applied.run ())
end

module Open_struct = struct
  module type Arg = sig val g : ?opened:int -> unit -> int end
  module type Holder_t = sig module Inner (M : Arg) : sig val run : unit -> int end end
  module Holder = struct
    module Inner (M : Arg) = struct let run () = M.g ~opened:1 () end
  end
  let packed = (module Holder : Holder_t)
  open struct module H = (val packed : Holder_t) end
  module Open_struct_arg : Arg = struct let g ?(opened = 0) () = opened end
  module Applied = H.Inner (Open_struct_arg)
  let run () = ignore (Applied.run ())
end

module Include_struct = struct
  module type Arg = sig val g : ?opened:int -> unit -> int end
  module type Holder_t = sig module Inner (M : Arg) : sig val run : unit -> int end end
  module Holder = struct
    module Inner (M : Arg) = struct let run () = M.g ~opened:1 () end
  end
  let packed = (module Holder : Holder_t)
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

module Unused_import = struct
  open Unpacked_unused
  module Victim : Arg = struct let g ?(unused_open = 0) () = unused_open end
  module Called_victim : Arg = struct let g ?(unused_open = 0) () = unused_open end
  let fns = [Victim.g]
  let run () = ignore (List.length fns); ignore (Called_victim.g ()); ignore (helper ())
end

module Mixed_open = struct
  module type Arg = sig val g : ?opened:int -> unit -> int end
  module type Holder_t = sig module Inner (M : Arg) : sig val run : unit -> int end end
  module Holder = struct
    module Inner (M : Arg) = struct let run () = M.g ~opened:1 () end
  end
  let packed = (module Holder : Holder_t)
  open struct
    module Used = (val packed : Holder_t)
    module Ignored = (val Unpacked_unused.packed : Unpacked_unused.Holder_t)
  end
  module Used_arg : Arg = struct let g ?(opened = 0) () = opened end
  module Victim : Unpacked_unused.Arg = struct let g ?(unused_open = 0) () = unused_open end
  module Applied = Used.Inner (Used_arg)
  let run () = ignore (Applied.run ()); ignore (Victim.g ())
end

module Aliases = struct
  module type Arg = sig val g : ?aliased:int -> unit -> int end
  module type Holder_t = sig module Inner (M : Arg) : sig val run : unit -> int end end
  module Holder = struct
    module Inner (M : Arg) = struct let run () = M.g ~aliased:1 () end
  end
  let packed = (module Holder : Holder_t)
  open (val packed : Holder_t)
  module Alias = Inner
  module Local_alias_arg : Arg = struct let g ?(aliased = 0) () = aliased end
  module Foreign_alias_arg : Unpacked_unused.Exported_alias.Arg = struct
    let g ?(foreign_alias = 0) () = foreign_alias
  end
  module Foreign_include_arg : Unpacked_unused.Exported_include.Arg = struct
    let g ?(foreign_include = 0) () = foreign_include
  end
  module Local = Alias (Local_alias_arg)
  module Foreign = Unpacked_unused.Exported_alias.Alias (Foreign_alias_arg)
  module Included = Unpacked_unused.Exported_include.Inner (Foreign_include_arg)
  let run () = ignore (Local.run ()); ignore (Foreign.run ()); ignore (Included.run ())
end

let run () =
  Direct.run ();
  Local.run ();
  Open_struct.run ();
  Include_struct.run ();
  Cross_unit.run ();
  Unrelated.run ();
  Unused_import.run ();
  Mixed_open.run ();
  Aliases.run ()
