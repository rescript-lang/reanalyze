let g ?(x = 0) () = x
let () = ignore (g ~x:1 ())
