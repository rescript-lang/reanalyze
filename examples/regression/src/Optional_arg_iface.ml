let iface_target ?x () = match x with Some x -> x | None -> 0
let iface_alias = iface_target
let iface_target_never ?y () = match y with Some y -> y | None -> 0
let iface_alias_never = iface_target_never
