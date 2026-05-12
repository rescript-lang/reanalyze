let live_optional ?used ?unused () =
  match used with
  | Some _ -> ()
  | None -> ()

let dead_optional ?also_dead () =
  match also_dead with
  | Some _ -> ()
  | None -> ()
