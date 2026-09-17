module type S = sig
  val f : unit -> int
end

module rec A : S = B
and B : S = A
