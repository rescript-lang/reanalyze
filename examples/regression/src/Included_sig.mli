include sig
  module type S = sig
    val f : unit -> int
  end

  module M : S
end
