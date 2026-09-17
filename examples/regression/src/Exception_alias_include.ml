include (Exception_alias_exports : sig
  module Nested : sig
    module Alias = Exception_nested_source.Inner
  end
end)
