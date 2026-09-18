module type S = sig
  module N : sig
    val f : unit -> int
  end
end

module rec A : S = B
and B : S = A

module C = A.N
