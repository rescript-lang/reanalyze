let tuple_alias ((left, right) as pair) =
  let values = [|left; right|] in
  (pair, values)

let optional ?value () = value

let local_module_value =
  let module Local = struct
    let value = 42
  end in
  Local.value

let local_exception_value =
  let exception Local_error in
  try raise Local_error with Local_error -> 1

let run () =
  let _pair, values = tuple_alias (local_module_value, local_exception_value) in
  (optional (), optional ~value:values.(0) ())
