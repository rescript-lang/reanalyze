module Ordered = struct
  type t = int

  let compare (left : int) right = Stdlib.compare left right
end

module Int_set = Set.Make (Ordered)

let use_set () = ignore (Int_set.singleton 1)
