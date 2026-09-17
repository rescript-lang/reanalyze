module Nested = struct
  module Alias = Exception_nested_source.Inner
end

module Local = struct
  exception Through_local_include = Not_found
  exception Unused = Not_found
end

module Local_nested = struct
  module Alias = Local
end
