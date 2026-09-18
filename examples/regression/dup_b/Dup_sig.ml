(* Same compilation unit name as dup_a/Dup_sig.ml, different content. *)
module type S = sig
  type t

  val f : t -> t

  val g : t -> t

  val h : t -> t
end
