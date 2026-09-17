let run () =
  (try raise Exception_nested_alias.Target.Direct with _ -> ());
  (try raise Exception_nested_chain.Target.Through_chain with _ -> ());
  (try raise Exception_nested_alias.Deep.Used with _ -> ());
  (try raise Exception_scoped_alias.Alias_chain.Direct with _ -> ());
  (try raise Exception_scoped_alias.Alias.Fresh with _ -> ());
  (try raise Exception_scoped_alias.Nested.Outer.Through_nested with _ -> ());
  (try raise Exception_scoped_alias.Nested.Alias.Shadowed with _ -> ());
  (try raise Exception_scoped_alias.Nested.Deep.Used with _ -> ());
  (try raise Exception_scoped_alias.Nested.External.Through_nested_alias with _ -> ());
  (try raise Exception_scoped_alias.Nested.Deeper.Alias.Through_deeper with _ -> ());
  (try raise Exception_scoped_alias.Constrained.Alias.Used with _ -> ());
  (try raise Exception_scoped_alias.Forward.Alias.Forwarded with _ -> ());
  (try raise Exception_scoped_alias.Recursive_alias.Rec_used with _ -> ());
  try raise Exception_alias_include.Nested.Alias.Through_include with _ -> ()
