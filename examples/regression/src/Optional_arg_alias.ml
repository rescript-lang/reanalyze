(* An alias or partial application of a function with optional parameters
   cannot drop them, so they are not reported on it. *)
let print_list = Format.pp_print_list
let print_ints = Format.pp_print_list Format.pp_print_int

(* A function defined here still owns its optional parameters. *)
let local_function ?unused_opt () =
  match unused_opt with Some x -> x | None -> 0

(* Calls through an alias or partial application are calls of the function
   it stands for. *)
let base prefix ?through_alias x =
  match through_alias with Some y -> prefix + x + y | None -> prefix + x
let partial = base 1
let base_never prefix ?never_through_alias x =
  match never_through_alias with Some y -> prefix + x + y | None -> prefix + x
let partial_never = base_never 1

let () =
  print_list Format.pp_print_string Format.std_formatter ["a"];
  print_ints Format.std_formatter [1];
  print_int (local_function ());
  print_int (partial ~through_alias:1 2);
  print_int (partial_never 2)
