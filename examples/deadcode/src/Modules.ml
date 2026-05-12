module LiveNested = struct
  let helper () = ()

  let value () = helper ()
end

module DeadNested = struct
  let helper () = ()

  let value () = helper ()
end

module PartlyLive = struct
  let used () = ()

  let unused () = ()
end

let use_partly_live () = PartlyLive.used ()
