module type N = sig
  val g : ?nested_arg:int -> unit -> int
end

module type S = sig
  module N : N
end

module F (M : S) = struct
  let run () = M.N.g ~nested_arg:1 ()
end

module Known : S = struct
  module N = struct
    let g ?(nested_arg = 0) () = nested_arg
  end
end

module A = F (Known)

module B = F (struct
  module N : N = struct
    let g ?(nested_arg = 0) () = nested_arg
  end
end)

module C = F (struct
  module Actual : N = struct
    let g ?(nested_arg = 0) () = nested_arg
  end

  module N = Actual
end)

module D = F (struct
  include struct
    module N : N = struct
      let g ?(nested_arg = 0) () = nested_arg
    end
  end
end)

module Packed_arg = struct
  module N : N = struct
    let g ?(nested_arg = 0) () = nested_arg
  end
end

let packed = (module Packed_arg : S)

module E = F ((val packed : S))

module Unrelated : S = struct
  module N = struct
    let g ?(nested_arg = 0) () = nested_arg
  end
end

module Foreign (M : Nested_arguments_packed.S) = struct
  let run () = M.N.g ~foreign_nested:1 ()
end

module Imported =
  Foreign ((val Nested_arguments_packed.packed : Nested_arguments_packed.S))

let run () =
  ignore (Imported.run ());
  Nested_arguments_packed.run ();
  ignore (A.run ());
  ignore (B.run ());
  ignore (C.run ());
  ignore (D.run ());
  ignore (E.run ());
  ignore (Unrelated.N.g ())
