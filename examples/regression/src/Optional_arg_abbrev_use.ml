(* An alias of a value exported with an abbreviation. *)
let aliased = Optional_arg_abbrev.abbrev_aliased

let () =
  print_int (aliased ~x:1 ());
  print_int (Optional_arg_abbrev.abbrev ~x:1 ());
  print_int (Optional_arg_abbrev.abbrev_never ())
