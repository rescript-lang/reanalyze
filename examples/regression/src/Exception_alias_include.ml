include (Exception_alias_exports : sig
  module Nested : sig
    module Alias = Exception_nested_source.Inner
  end

  module Local : sig
    exception Through_local_include
    exception Unused
  end

  module Local_nested : sig
    module Alias = Local
  end
end)
