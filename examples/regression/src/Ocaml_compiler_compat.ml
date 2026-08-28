(* Exercise compiler-libs representations that changed in OCaml 5.4 and 5.5.
   The regression ensures reanalyze can traverse the resulting typed tree
   across all supported compiler versions. *)

(* OCaml 5.4 changed tuple elements to carry an optional label and added an
   extra type field to alias patterns. It also added a mutability flag to array
   expressions. *)
let tuple_alias ((left, right) as pair) =
  let values = [|left; right|] in
  (pair, values)

let optional ?value () = value

(* OCaml 5.5 represents local modules and exceptions using Texp_struct_item
   instead of Texp_letmodule and Texp_letexception. *)
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
  (* OCaml 5.4 replaced expression options in application arguments with
     explicit Omitted and Arg constructors. Exercise both forms. *)
  ignore (optional (), optional ~value:values.(0) ())
