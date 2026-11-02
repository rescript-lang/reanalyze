(* Re-exports declare the same constructors and labels as the original type:
   constructing or reading through either name uses both declarations. *)
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

val read : job -> int
