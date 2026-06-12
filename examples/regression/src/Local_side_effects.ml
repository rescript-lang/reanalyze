let registry = ref []

let register callback =
  registry := callback :: !registry;
  List.length !registry

let start () =
  let process () = () in
  let _info = register process in
  ()
