module type S = sig val g : ?x:int -> unit -> int end
module Chosen_impl = struct let g ?(x = 0) () = x end
module Target : S = Chosen_impl
let marker_a = ()
