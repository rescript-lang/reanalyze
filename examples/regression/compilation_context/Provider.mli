module type S = sig
  val g : ?context:int -> unit -> int
end

module Op (M : S) : sig
  val run : unit -> int
end
