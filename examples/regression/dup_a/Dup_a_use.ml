module M = Dup_a_impl.Make (struct
  type t = int
end)

let run () = M.f 1
let () = ignore (run ())
