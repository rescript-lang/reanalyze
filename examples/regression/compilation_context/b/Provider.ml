module type S = sig
  val g : ?context:int -> unit -> int
end

module Op (M : S) = struct
  let run () = M.g ()
end
