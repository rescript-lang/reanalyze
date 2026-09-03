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
