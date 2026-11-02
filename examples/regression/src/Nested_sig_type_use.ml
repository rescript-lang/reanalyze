let () =
  print_string (Nested_sig_type.Color.describe Nested_sig_type.Color.Auto);
  print_string (Nested_sig_type.Color.describe Nested_sig_type.Color.Never);
  print_string
    (Nested_sig_type.Color.error
       {Nested_sig_type.Color.error = "e"; unused_style = "u"})
