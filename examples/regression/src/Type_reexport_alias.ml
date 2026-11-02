(* A re-export through a local module alias. *)
module Child = Type_reexport_orig

type job = Child.job = {
  read_through_original : int;
  read_through_reexport : int;
  read_through_alias : int;
  never_read : int;
}

let read job = job.read_through_alias
