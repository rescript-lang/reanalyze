type change = Built_through_reexport | Built_directly | Never_built

type job = {
  read_through_original : int;
  read_through_reexport : int;
  read_through_alias : int;
  never_read : int;
}

let describe = function
  | Built_through_reexport -> "reexport"
  | Built_directly -> "direct"
  | Never_built -> "never"

let read job = job.read_through_original
