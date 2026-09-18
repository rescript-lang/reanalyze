module Mixed_holders = struct
  module type S = sig
    val g : ?mixed:int -> unit -> int
  end

  module type Holder = sig
    module Inner (M : S) : sig
      val run : unit -> int
    end
  end

  module Apply (H : Holder) (M : S) = struct
    module A = H.Inner (M)

    let run = A.run
  end

  module Known = struct
    module Inner (M : S) = struct
      let run () = M.g ~mixed:1 ()
    end
  end

  module Known_arg : S = struct
    let g ?(mixed = 0) () = mixed
  end

  module Anonymous_arg : S = struct
    let g ?(mixed = 0) () = mixed
  end

  module Included_arg : S = struct
    let g ?(mixed = 0) () = mixed
  end

  module Omitted_arg : S = struct
    let g ?(mixed = 0) () = mixed
  end

  module Unrelated_arg : S = struct
    let g ?(mixed = 0) () = mixed
  end

  module A = Apply (Known) (Known_arg)

  module B =
    Apply
      (struct
        module Inner (M : S) = struct
          let run () = M.g ~mixed:1 ()
        end
      end)
      (Anonymous_arg)

  module C =
    Apply
      (struct
        module Nested = struct
          module F (M : S) = struct
            let run () = M.g ~mixed:1 ()
          end
        end

        include struct
          module Inner = Nested.F
        end
      end)
      (Included_arg)

  module D =
    Apply
      (struct
        module Inner (M : S) = struct
          let run () = M.g ()
        end
      end)
      (Omitted_arg)

  let run () =
    ignore (A.run ());
    ignore (B.run ());
    ignore (C.run ());
    ignore (D.run ());
    ignore (Unrelated_arg.g ())
end

module Partial_result = struct
  module type S = sig end

  module type FT = functor (M : S) (N : S) -> sig
    val run : ?result:int -> unit -> int
    val unused : unit -> int
  end

  module type Half = functor (N : S) -> sig
    val run : ?result:int -> unit -> int
    val unused : unit -> int
  end

  module F (M : S) (N : S) = struct
    let run ?(result = 0) () = result
    let unused () = 0
  end

  let packed = (module F : FT)

  module G = (val packed : FT)
  module H = G (struct end)

  let repacked = (module H : Half)

  module I = (val repacked : Half)
  module J = I (struct end)
  module K = H (struct end)

  (* Two paths reach the same implementation; neither may duplicate calls. *)
  let run () =
    ignore (J.run ~result:1 ());
    ignore (K.run ~result:2 ())
end

module Local_alias = struct
  module type S = sig
    val g : ?local_alias:int -> unit -> int
  end

  module type Holder_t = sig
    module Inner (M : S) : sig
      val run : unit -> int
    end
  end

  module Holder = struct
    module Inner (M : S) = struct
      let run () = M.g ~local_alias:1 ()
    end
  end

  let packed = (module Holder : Holder_t)

  module Arg : S = struct
    let g ?(local_alias = 0) () = local_alias
  end

  let run () =
    let open (val packed : Holder_t) in
    let module Alias = Inner in
    let module A = Alias (Arg) in
    ignore (A.run ())
end

module Recursive_alias = struct
  module type S = sig
    val g : ?recursive_alias:int -> unit -> int
  end

  module type FT = functor (M : S) -> sig
    val run : unit -> int
  end

  module type Holder_t = sig
    module Inner : FT
  end

  module Holder = struct
    module Inner (M : S) = struct
      let run () = M.g ~recursive_alias:1 ()
    end
  end

  let packed = (module Holder : Holder_t)

  open (val packed : Holder_t)
  module rec Alias : FT = Inner

  module Arg : S = struct
    let g ?(recursive_alias = 0) () = recursive_alias
  end

  module Applied = Alias (Arg)

  let run () = ignore (Applied.run ())
end

let run () =
  Mixed_holders.run ();
  Partial_result.run ();
  Local_alias.run ();
  Recursive_alias.run ()
