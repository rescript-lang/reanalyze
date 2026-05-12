type live_record = { id : int }

type live_variant =
  | LiveA
  | LiveB of live_record

type exposed_but_unused = string

type dead_record = { dead_id : int }

type dead_variant =
  | DeadA
  | DeadB of dead_record

let make_live id = LiveB { id }

let make_dead id = DeadB { dead_id = id }
