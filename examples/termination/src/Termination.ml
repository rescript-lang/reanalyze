let progress =
  let counter = ref (Random.int 100) in
  fun () ->
    if !counter < 0 then assert false;
    decr counter

let progress2 = progress

module Progress = struct
  module Nested = struct
    let f = progress
  end
end

let[@progress progress] rec just_return () = ()

let[@progress progress] rec always_loop () = always_loop ()

let[@progress progress] rec always_progress () =
  progress ();
  always_progress ()

let[@progress progress] rec always_progress_wrong_order () =
  always_progress_wrong_order ();
  progress ()

let[@progress progress] rec do_not_alias () =
  let alias = do_not_alias in
  alias ()

let[@progress (progress, progress2)] rec progress_on_both_branches x =
  if x > 3 then progress () else progress2 ();
  progress_on_both_branches x

let[@progress progress] rec progress_on_one_branch x =
  if x > 3 then progress ();
  progress_on_one_branch x

let[@progress progress] rec test_parametric_function x =
  if x > 3 then progress ();
  test_parametric_function2 x

and test_parametric_function2 x =
  call_parse_function x ~parse_function:test_parametric_function

and call_parse_function x ~parse_function = parse_function x

let[@progress Progress.Nested.f] rec test_cache_hit x =
  if x > 0 then (
    do_nothing x;
    do_nothing x;
    Progress.Nested.f ());
  test_cache_hit x

and do_nothing _ = ()

let[@progress progress] rec eval_order_is_not_left_to_right x =
  let combine_two_units ((), ()) = () in
  combine_two_units (progress (), eval_order_is_not_left_to_right x)

let[@progress progress] rec eval_order_is_not_right_to_left x =
  let combine_two_units ((), ()) = () in
  combine_two_units (eval_order_is_not_right_to_left x, progress ())

let[@progress progress] rec first_argument_is_always_evaluated x =
  let combine_two_units ((), ()) = () in
  combine_two_units (progress (), ());
  first_argument_is_always_evaluated x

let[@progress progress] rec second_argument_is_always_evaluated x =
  let combine_two_units ((), ()) = () in
  combine_two_units ((), progress ());
  second_argument_is_always_evaluated x
