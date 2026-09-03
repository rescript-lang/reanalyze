type t = {name : string}
let create name = {name}
let equal a b = a.name = b.name
let hash a = String.length a.name
