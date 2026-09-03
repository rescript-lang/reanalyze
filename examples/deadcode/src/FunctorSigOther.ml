(* Constrained by the same module type as FunctorSigMli.Make, but never
   instantiated: calls through FunctorSigMli instances must not keep it live. *)
module Make (K : sig
  type t
end) : FunctorSigGen.S = struct
  let find_opt k = Some k

  let unused_in_sig k = k

  let with_opt ?(x = 0) () = x
end
