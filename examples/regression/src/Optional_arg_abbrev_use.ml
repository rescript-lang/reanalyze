let () =
  print_int (Optional_arg_abbrev.abbrev ~x:1 ());
  print_int (Optional_arg_abbrev.abbrev_never ())
