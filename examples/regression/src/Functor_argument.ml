module Ordered = struct
  type t = int

  let compare (left : int) right = Stdlib.compare left right
  let unused () = ()
end

module Int_set = Set.Make (Ordered)

let use_set () = ignore (Int_set.singleton 1)

module Extra_fields = struct
  type extension = ..
  type extension += Extra

  let before () = ()
end

module Anonymous_set = Set.Make (struct
  include Extra_fields

  type t = int

  let compare (left : int) right = Stdlib.compare left right
  let unused () = ()
end)

let use_anonymous_set () = ignore (Anonymous_set.singleton 1)
