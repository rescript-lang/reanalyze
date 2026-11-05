type change = Type_reexport_orig.change =
  | Built_through_reexport
  | Built_directly
  | Never_built

type job = Type_reexport_orig.job = {
  read_through_original : int;
  read_through_reexport : int;
  read_through_alias : int;
  never_read : int;
}

let read job = job.read_through_reexport
