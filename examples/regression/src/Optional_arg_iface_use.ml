let () =
  print_int (Optional_arg_iface.iface_alias ~x:1 ());
  print_int (Optional_arg_iface.iface_alias_never ())
