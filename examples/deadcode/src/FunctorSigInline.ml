module Make (K : sig
  type t
end) : FunctorSigGen.T = struct
  let lookup k = Some k

  let unused_in_inline_sig k = k

  let truly_dead_inline k = k
end
