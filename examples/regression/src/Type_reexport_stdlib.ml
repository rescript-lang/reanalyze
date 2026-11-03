(* A re-export of a type outside the analysis: its constructors are reported
   by their uses here alone. *)
type 'a node = 'a Seq.node = Nil | Cons of 'a * 'a Seq.t

let () = ignore (Nil : int node)
