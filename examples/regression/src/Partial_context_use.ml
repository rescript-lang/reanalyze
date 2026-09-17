module P = Attribution_sweep.Partial_context
module Foreign_supplied_arg : P.S = struct let g ?(partial = 0) () = partial end
module Foreign_omitted_arg : P.S = struct let g ?(partial = 0) () = partial end
module Supplied = P.Supply (Foreign_supplied_arg)
module Omitted = P.Omit (Foreign_omitted_arg)
let run () = ignore (Supplied.run ()); ignore (Omitted.run ())
