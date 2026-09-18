(* The escaping holder's lexical range does not contain the functor it
   exports. Both aliases and includes must carry that definition with it. *)
module type Alias_arg = sig
  val g : ?alias:int -> unit -> int
end

module type Alias_holder = sig
  module Inner : functor (M : Alias_arg) -> sig
    val run : unit -> int
  end
end

module Alias_inner (M : Alias_arg) = struct
  let run () = M.g ~alias:1 ()
end

module Holder_alias = struct
  module Inner = Alias_inner
end

module Escaped_alias_arg : Alias_arg = struct
  let g ?(alias = 0) () = alias
end

let packed_alias = (module Holder_alias : Alias_holder)

let apply_alias (module H : Alias_holder) =
  let module A = H.Inner (Escaped_alias_arg) in
  A.run ()

module type Include_arg = sig
  val g : ?included:int -> unit -> int
end

module type Include_holder = sig
  module Inner : functor (M : Include_arg) -> sig
    val run : unit -> int
  end
end

module Included = struct
  module Inner (M : Include_arg) = struct
    let run () = M.g ~included:1 ()
  end
end

module Holder_include = struct
  include Included
end

module Escaped_include_arg : Include_arg = struct
  let g ?(included = 0) () = included
end

let packed_include = (module Holder_include : Include_holder)

let apply_include (module H : Include_holder) =
  let module A = H.Inner (Escaped_include_arg) in
  A.run ()

let run () = ignore (apply_alias packed_alias + apply_include packed_include)
