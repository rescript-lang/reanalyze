type fn = ?x:int -> unit -> int

let abbrev ?x () = match x with Some x -> x | None -> 0
let abbrev_never ?x () = match x with Some x -> x | None -> 1
