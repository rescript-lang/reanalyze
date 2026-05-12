module Source = struct
  let included_used () = ()

  let included_unused () = ()
end

include Source

let use_included () = included_used ()
