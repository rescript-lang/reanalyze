module type S = sig val g : ?x:int -> unit -> int end
module Unrelated_impl = struct let g ?(x = 0) () = x end
module Target : S = Unrelated_impl
let marker_b = ()
