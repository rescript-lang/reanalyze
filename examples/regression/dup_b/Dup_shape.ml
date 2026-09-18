module B_unused : Dup_sig.S with type t = int = struct
  type t = int
  let f x = x
  let g x = x
  let h x = x
end
