module Make (K : sig
  type t
end) : Shared_signature.S = struct
  let f () = 1
end
