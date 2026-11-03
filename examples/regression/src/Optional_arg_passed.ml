(* A function passed as an argument with its optional parameters intact can
   receive them from the callee. *)
let find_component (lookup : ?loc:_ -> _) x = lookup ~loc:1 x

let local_lookup ?loc x = match loc with Some l -> x * l | None -> x

let () =
  print_int (find_component local_lookup 2);
  print_int (find_component Optional_arg_passed_env.lookup 2);
  print_int (Optional_arg_passed_env.never_passed 3)
