let run () =
  (try raise Exception_nested_alias.Target.Direct with _ -> ());
  (try raise Exception_nested_chain.Target.Through_chain with _ -> ());
  try raise Exception_nested_alias.Deep.Used with _ -> ()
