module type S = sig
  val g : ?split:int -> unit -> int
end

module Used (_ : sig end) : S = struct
  let g ?(split = 0) () = split
end

module Unused (_ : sig end) : S = struct
  let g ?(split = 0) () = split + 1
end
