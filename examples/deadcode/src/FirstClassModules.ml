module type Runnable = sig
  val run : unit -> unit
end

module LiveRunner = struct
  let run () = ()
end

module DeadRunner = struct
  let run () = ()
end

let run_module (module R : Runnable) = R.run ()

let run () = run_module (module LiveRunner)
