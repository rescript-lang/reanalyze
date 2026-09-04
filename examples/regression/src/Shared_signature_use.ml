module H = Shared_signature_used.Make (struct
  type t = int
end)

let run () = ignore (H.f ())
