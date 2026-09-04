(* A named module type declared inside a module: its items must not count as
   declarations, so [Unused.f] is reported dead and [Used.f] live. *)
module Outer = struct
  module type S = sig
    val f : unit -> int
  end

  module Used : S = struct
    let f () = 1
  end

  module Unused : S = struct
    let f () = 2
  end
end

let run () = ignore (Outer.Used.f ())
