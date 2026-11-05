(* Values whose interface names their type with an abbreviation, which
   hides their optional parameters. *)
type fn = ?x:int -> unit -> int

val abbrev : fn
val abbrev_never : fn
val abbrev_aliased : fn
