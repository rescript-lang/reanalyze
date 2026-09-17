(* The indirect application of Outer becomes known after its body has
   already been instantiated for the direct application. *)
module type Arg = sig
  val g : ?y:int -> unit -> int
end

module type FT = functor (M : Arg) -> sig
  val run : unit -> int
end

module type Higher = functor (F : FT) (M : Arg) -> sig
  val run : unit -> int
end

module Impl_a (M : Arg) = struct
  let run () = M.g ~y:1 ()
end

module Impl_b (M : Arg) = struct
  let run () = M.g ~y:2 ()
end

module Impl_c (M : Arg) = struct
  let run () = M.g ()
end

module Fixpoint_a : Arg = struct
  let g ?(y = 0) () = y
end

module Fixpoint_b : Arg = struct
  let g ?(y = 0) () = y
end

module Fixpoint_c : Arg = struct
  let g ?(y = 0) () = y
end

module Outer (F : FT) (M : Arg) = F (M)
module Top (H : Higher) (F : FT) (M : Arg) = H (F) (M)
module Direct = Outer (Impl_a) (Fixpoint_a)
module Indirect = Top (Outer) (Impl_b) (Fixpoint_b)
module Indirect_c = Top (Outer) (Impl_c) (Fixpoint_c)

let run () = ignore (Direct.run () + Indirect.run () + Indirect_c.run ())
