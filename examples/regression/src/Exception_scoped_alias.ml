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

module type Signature = sig
  module Source : sig
    exception Used
    exception Forwarded
    exception Unused
  end

  module Alias = Source
end

module Constrained : Signature = struct
  module Source = struct
    exception Used = Not_found
    exception Forwarded = Not_found
    exception Unused = Not_found
  end

  module Alias = Source
end

module Forward : Signature = Constrained

module Other : Signature = struct
  module Source = struct
    exception Used = Not_found
    exception Forwarded = Not_found
    exception Unused = Not_found
  end

  module Alias = Source
end

module Alias = Source
module Alias_chain = Alias

module rec Recursive_alias : sig
  exception Rec_used
  exception Rec_unused
end = Recursive_source

and Recursive_source : sig
  exception Rec_used
  exception Rec_unused
end = struct
  exception Rec_used = Not_found
  exception Rec_unused = Not_found
end

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
