module Make (K : sig
  type t
end) : Shared_signature.S = struct
  let f () = 2
end
