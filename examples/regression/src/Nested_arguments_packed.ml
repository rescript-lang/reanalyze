module type N = sig
  val g : ?foreign_nested:int -> unit -> int
end

module type S = sig
  module N : N
end

module Actual : S = struct
  module N : N = struct
    let g ?(foreign_nested = 0) () = foreign_nested
  end
end

let packed = (module Actual : S)

module Unrelated : S = struct
  module N = struct
    let g ?(foreign_nested = 0) () = foreign_nested
  end
end

let run () = ignore (Unrelated.N.g ())
