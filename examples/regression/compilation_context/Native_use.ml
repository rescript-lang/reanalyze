module A = Native_provider.Make (Native_provider.Arg)

let () = ignore (A.run ())
