let job =
  {
    Type_reexport.read_through_original = 1;
    read_through_reexport = 2;
    read_through_alias = 4;
    never_read = 3;
  }

let () =
  print_string (Type_reexport_orig.describe Type_reexport.Built_through_reexport);
  print_string (Type_reexport_orig.describe Type_reexport_orig.Built_directly);
  print_int
    (Type_reexport_orig.read job + Type_reexport.read job
   + Type_reexport_alias.read job)
