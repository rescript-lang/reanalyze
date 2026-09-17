module Chosen = Split.Used (struct end)
module Unchosen = Split.Unused (struct end)

let () = ignore (Chosen.g ~split:1 ())
