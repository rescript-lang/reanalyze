module H = FunctorSigMli.Make (struct
  type t = int
end)

module I = FunctorSigInline.Make (struct
  type t = int
end)

let run () =
  match (H.find_opt 1, I.lookup 2) with
  | Some _, Some _ -> print_endline "x"
  | _ -> ()
