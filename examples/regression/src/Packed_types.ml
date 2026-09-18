module type Arg = sig
  val g : ?x:int -> unit -> int
end

module type FT = functor (M : Arg) -> sig
  val run : unit -> int
end
