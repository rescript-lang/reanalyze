module Make (K : sig
  type t
end) =
struct
  let find_opt k = Some k

  let unused_in_sig k = k

  let truly_dead k = k
end
