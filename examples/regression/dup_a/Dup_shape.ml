module A_chosen : Dup_sig.S with type t = int = struct
  type t = int
  let f x = x
  let g x = x
end

module A_unused : Dup_sig.S with type t = int = struct
  type t = int
  let f x = x
  let g x = x
end
