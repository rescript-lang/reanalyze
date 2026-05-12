type live_record

type live_variant =
  | LiveA
  | LiveB of live_record

type exposed_but_unused

val make_live : int -> live_variant
