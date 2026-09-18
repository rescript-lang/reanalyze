(* Same compilation unit name as dup_b/Dup_sig.ml, different content. *)
module type S = sig
  type t

  val f : t -> t

  val g : t -> t
end
