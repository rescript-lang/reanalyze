include sig
  module type S = sig
    val f : unit -> int
  end

  module M : S
end

module W : sig
  type t

  module type S2 = sig
    val f : unit -> int
  end

  module X : S2
end
with type t = int

module W2 : sig
  module type S

  module X : S
end
with module type S = sig
  val f : unit -> int
end

module W3 : module type of struct
  module type S3 = sig
    val f : unit -> int
  end

  module X : S3 = struct
    let f () = 9
  end
end
