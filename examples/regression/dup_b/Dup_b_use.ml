module M = Dup_b_impl.Make (struct
  type t = int
end)

let run () = M.g 1
let () = ignore (run ())
