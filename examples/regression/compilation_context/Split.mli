module type S = sig
  val g : ?split:int -> unit -> int
end

module Used (_ : sig end) : S
module Unused (_ : sig end) : S
