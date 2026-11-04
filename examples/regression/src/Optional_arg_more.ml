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

(* A binding stands for the applied function only with the optional
   parameters that function leaves. [wrapped_g]'s [?x] comes from [wrapped]
   through [wrap]'s ['a], not from [wrap]'s own [?x], which nobody supplies. *)
let wrap ?x f =
  ignore x;
  f

let wrapped ?x () = match x with Some x -> x | None -> 0
let wrapped_g = wrap wrapped

(* A partial application that stands for the function passes its own
   arguments on every call through it: [x] is always supplied. *)
let partial_x ?x ?y () =
  (match x with Some x -> x | None -> 0) + match y with Some y -> y | None -> 0

let partial_xp = partial_x ~x:1

(* An application that does not stand for the function it applies, through
   an identifier or not, leaves its result's optional parameters to the
   function among its arguments. *)
let via_lambda ?c () = match c with Some c -> c | None -> 0
let lambda_applied = (fun h -> h) via_lambda

(* A partial application leaves the optional parameters it skips. *)
let skipped ?x ~a () = match x with Some x -> x + a | None -> a
let skipped_partial = skipped ~a:1

(* A function passed to a parameter of a named function type may receive
   its optional parameters. *)
type lookup = ?loc:int -> int -> int

let find (f : lookup) = f ~loc:1 2
let named_lookup ?loc x = match loc with Some l -> l + x | None -> x

(* A binding constrained with an abbreviation that hides the labels is
   still an alias; calls through it are recorded although its type shows
   no optional parameters. *)
type fn = ?x:int -> unit -> int

let plain ?x () = match x with Some x -> x | None -> 0
let plain_g : fn = plain

let () =
  print_int (partial_xp ());
  print_int (partial_xp ~y:2 ());
  print_int (lambda_applied ~c:1 ());
  print_int (plain_g ~x:1 ());
  print_int (plain ());
  print_int (wrapped_g ~x:1 ());
  print_int (skipped_partial ~x:2 ());
  print_int (find named_lookup);
  print_int (sig_alias ~x:1 ());
  print_int (let_in_fun ());
  print_int (if_fun ());
  ignore ignored;
  print_int (ignored ());
  print_int (!stored ())
