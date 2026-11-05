type change = Built_through_reexport | Built_directly | Never_built

type job = {
  read_through_original : int;
  read_through_reexport : int;
  read_through_alias : int;
  never_read : int;
}

val describe : change -> string
val read : job -> int
