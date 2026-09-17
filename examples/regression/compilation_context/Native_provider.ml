module type S = sig
  val g : ?native:int -> unit -> int
end

module Arg : S = struct
  let g ?(native = 0) () = native
end

module Make (M : S) = struct
  let run () = M.g ~native:1 ()
end
