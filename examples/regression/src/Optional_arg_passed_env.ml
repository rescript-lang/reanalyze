let lookup ?loc x = match loc with Some l -> x + l | None -> x
let never_passed ?loc x = match loc with Some l -> x + l | None -> x
