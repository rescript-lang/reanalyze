module type Arg = sig val g : ?unused_open:int -> unit -> int end
module type Holder_t = sig module Inner (M : Arg) : sig val run : unit -> int end end
module Holder = struct
  module Inner (M : Arg) = struct let run () = M.g ~unused_open:1 () end
end
let packed = (module Holder : Holder_t)
module Unused_holder = (val packed : Holder_t)
let helper () = 42

module Exported_include = struct
  module type Arg = sig val g : ?foreign_include:int -> unit -> int end
  module type Holder_t = sig module Inner (M : Arg) : sig val run : unit -> int end end
  module Holder = struct
    module Inner (M : Arg) = struct let run () = M.g ~foreign_include:1 () end
  end
  let packed = (module Holder : Holder_t)
  include (val packed : Holder_t)
end

module Exported_alias = struct
  module type Arg = sig val g : ?foreign_alias:int -> unit -> int end
  module type Holder_t = sig module Inner (M : Arg) : sig val run : unit -> int end end
  module Holder = struct
    module Inner (M : Arg) = struct let run () = M.g ~foreign_alias:1 () end
  end
  let packed = (module Holder : Holder_t)
  include (val packed : Holder_t)
  module Alias = Inner
end
