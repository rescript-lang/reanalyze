(* An ordinary unresolved reference must remain forwardable even when a
   parameter reference to the same item is visited later in the binding. *)
module Parameter_first = struct
  module type S = sig
    val f : unit -> int
  end

  module Used : S = struct
    let f () = 11
  end

  module Param : S = struct
    let f () = 12
  end

  let packed = (module Used : S)
  let through x = x

  module F (M : S) = struct
    let run () =
      let module N = (val through packed : S) in
      ignore (M.f ());
      N.f ()
  end

  module A = F (Param)
end

module Ordinary_first = struct
  module type S = sig
    val f : unit -> int
  end

  module Used : S = struct
    let f () = 21
  end

  module Param : S = struct
    let f () = 22
  end

  let packed = (module Used : S)
  let through x = x

  module F (M : S) = struct
    let run () =
      let module N = (val through packed : S) in
      ignore (N.f ());
      M.f ()
  end

  module A = F (Param)
end

let run () = ignore (Parameter_first.A.run () + Ordinary_first.A.run ())
