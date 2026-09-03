module type S = sig
  val f : unit -> int
end

module M : S = struct
  let f () = 5
end

module W = struct
  type t = int

  module type S2 = sig
    val f : unit -> int
  end

  module X = struct
    let f () = 7
  end
end

module W2 = struct
  module type S = sig
    val f : unit -> int
  end

  module X = struct
    let f () = 8
  end
end
