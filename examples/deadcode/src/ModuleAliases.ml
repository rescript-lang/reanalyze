module Source = struct
  let used_through_alias () = ()

  let unused_even_with_alias () = ()
end

module Alias = Source

let use_alias () = Alias.used_through_alias ()
