(* A named module type shared by two functors. Only [Used] is instantiated, so
   [Unused.Make.f] must be reported dead: a call through [Used]'s instance must
   not keep [Unused]'s implementation alive. *)
module type S = sig
  val f : unit -> int
end
