(* Named module types used as functor result signatures from other files. *)
module type S = sig
  val find_opt : int -> int option

  val unused_in_sig : int -> int
end

module type T = sig
  val lookup : int -> int option

  val unused_in_inline_sig : int -> int
end
