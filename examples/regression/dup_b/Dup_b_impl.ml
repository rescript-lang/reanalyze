module Make (K : sig
  type t
end) : Dup_sig.S with type t = K.t = struct
  type t = K.t

  let f x = x

  let g x = x

  let h x = x
end
