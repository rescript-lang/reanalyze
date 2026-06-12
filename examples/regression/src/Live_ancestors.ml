module Parent = struct
  let dead_top () = ()

  module Child = struct
    let live () = ()
  end
end

let use_child () = Parent.Child.live ()
