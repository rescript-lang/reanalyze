module type Arg = sig val g : ?opened:int -> unit -> int end
module type Holder_t = sig module Inner (M : Arg) : sig val run : unit -> int end end
