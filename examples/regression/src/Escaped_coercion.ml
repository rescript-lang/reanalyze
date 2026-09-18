module Escaped_only = struct
  module type Arg = sig
    val needed : unit -> int
    val unused : unit -> int
  end
  module Inner (M : sig val needed : unit -> int end) = struct
    let run () = M.needed ()
  end
  module Outer (M : Arg) = Inner (M)
  module type FT = functor (M : Arg) -> sig val run : unit -> int end
  module Possible_arg : Arg = struct
    let needed () = 1
    let unused () = 2
  end
  let registry = [(module Outer : FT)]
  let run () = ignore (List.length registry)
end

module Known_and_escaped = struct
  module type Arg = sig
    val needed : unit -> int
    val unused : unit -> int
  end
  module Inner (M : sig val needed : unit -> int end) = struct
    let run () = M.needed ()
  end
  module Outer (M : Arg) = Inner (M)
  module type FT = functor (M : Arg) -> sig val run : unit -> int end
  module Known_arg : Arg = struct
    let needed () = 1
    let unused () = 2
  end
  module Possible_arg : Arg = struct
    let needed () = 3
    let unused () = 4
  end
  module Applied = Outer (Known_arg)
  let registry = [(module Outer : FT)]
  let run () = ignore (Applied.run ()); ignore (List.length registry)
end

module Never_applied = struct
  module type Arg = sig val needed : unit -> int end
  module Inner (M : Arg) = struct let run () = M.needed () end
  module Outer (M : Arg) = Inner (M)
  module Unrelated_arg : Arg = struct let needed () = 1 end
end

module Known_only = struct
  module type Arg = sig val needed : unit -> int end
  module Inner (M : Arg) = struct let run () = M.needed () end
  module Outer (M : Arg) = Inner (M)
  module Known_arg : Arg = struct let needed () = 1 end
  module Unrelated_arg : Arg = struct let needed () = 2 end
  module Applied = Outer (Known_arg)
  let run () = ignore (Applied.run ())
end

module Nested_stored = struct
  module type Item = sig val needed : unit -> int val unused : unit -> int end
  module type Arg = sig module N : Item end
  module Inner (M : sig val needed : unit -> int end) = struct
    let run () = M.needed ()
  end
  module Outer (M : Arg) = Inner (M.N)
  module type FT = functor (M : Arg) -> sig val run : unit -> int end
  module Possible_arg : Arg = struct
    module N = struct let needed () = 1 let unused () = 2 end
  end
  let packed = (module Outer : FT)
  let registry = [packed]
  let run () = ignore (List.length registry)
end

let run () =
  Escaped_only.run ();
  Known_and_escaped.run ();
  Known_only.run ();
  Nested_stored.run ()
