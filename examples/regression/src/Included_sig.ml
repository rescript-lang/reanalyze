module type S = sig
  val f : unit -> int
end

module M : S = struct
  let f () = 5
end
