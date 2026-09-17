module type S = sig
  val g : ?context:int -> unit -> int
end

module Apply (M : S) = Provider.Op (M)
module Curried (Ignored : S) (M : S) = Provider.Op (M)

module Seed = struct
  let g ?(context = 0) () = context
end

module Half = Curried (Seed)
module Alias = Half

module type FT = functor (M : S) -> sig
  val run : unit -> int
end

let packed = (module Alias : FT)
