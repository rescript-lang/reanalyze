module Unpacked_arg : Unpacked_functor.Arg = struct let g ?(x = 0) () = x end
module Unpacked_unused : Unpacked_functor.Arg = struct let g ?(x = 0) () = x end
module Applied = Unpacked_functor.Alias (Unpacked_arg)
module Unpacked_nested_arg : Unpacked_functor.Nested_arg = struct
  let g ?(nested = 0) () = nested
end
module Applied_nested = Unpacked_functor.Holder.Inner (Unpacked_nested_arg)
let run () =
  ignore (Applied.run ());
  ignore (Applied_nested.run ());
  ignore (Unpacked_unused.g ())
