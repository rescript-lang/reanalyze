module Source = struct
  exception Direct = Not_found
  exception Through_nested = Not_found
  exception Shadowed = Not_found
  exception Fresh
  exception Unused = Not_found

  module Deep = struct
    exception Used = Not_found
    exception Unused = Not_found
  end
end

module Alias = Source
module Alias_chain = Alias

module Nested = struct
  module Outer = Source

  module Source = struct
    exception Shadowed = Not_found
    exception Through_deeper = Not_found
    exception Unused = Not_found
  end

  module Alias = Source
  module Deep = Outer.Deep
  module External = Exception_nested_source.Inner

  module Deeper = struct
    module Alias = Source
  end
end
