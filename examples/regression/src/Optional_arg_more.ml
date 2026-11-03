(* An alias of a value of a module constrained by a signature. *)
module type S = sig
  val sig_f : ?x:int -> unit -> int
end

module M : S = struct
  let sig_f ?x () = match x with Some x -> x | None -> 0
end

let sig_alias = M.sig_f

(* Functions whose body is not syntactically a function still own their
   optional parameters. *)
let let_in_fun =
  let y = 1 in
  fun ?x () -> match x with Some x -> x + y | None -> y

let if_fun =
  if Sys.argv = [||] then fun ?x () -> match x with Some x -> x | None -> 1
  else fun ?x () -> match x with Some x -> x | None -> 2

(* Passing a function to a parameter of type ['a] does not supply its
   optional parameters. *)
let ignored ?x () = match x with Some x -> x | None -> 0
let in_ref ?y () = match y with Some y -> y | None -> 0
let stored = ref in_ref

let () =
  print_int (sig_alias ~x:1 ());
  print_int (let_in_fun ());
  print_int (if_fun ());
  ignore ignored;
  print_int (ignored ());
  print_int (!stored ())
