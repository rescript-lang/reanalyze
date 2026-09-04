(* A functor defined in a third unit, reached through an alias in a second
   unit's included module, from a first unit's functor result. *)
module F (M : Shared_signature.O) = struct
  let run () = M.g ~x:1 ()
end
