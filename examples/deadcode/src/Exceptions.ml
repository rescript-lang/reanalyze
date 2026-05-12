exception A

let raises () = raise A

let catches () =
  try raises () with
  | A -> ()

let leaks () = raises ()
