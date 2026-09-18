module Make (K : sig
  type t
end) =
struct
  let find_opt k = Some k

  let unused_in_sig k = k

  let truly_dead k = k

  let with_opt ?(x = 0) () = x
end
