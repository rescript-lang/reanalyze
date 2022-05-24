type t = {
  mutable dce : bool;
  mutable exception_ : bool;
  mutable termination : bool;
  mutable noalloc : bool;
}

let default () =
  {dce = false; exception_ = false; noalloc = false; termination = false}

let addConfig x newConfig =
  if newConfig.dce then x.dce <- true;
  if newConfig.exception_ then x.exception_ <- true;
  if newConfig.termination then x.termination <- true;
  if newConfig.noalloc then x.noalloc <- true

let all x =
  x.dce <- true;
  x.exception_ <- true;
  x.termination <- true

let dce x = x.dce <- true

let exception_ x = x.exception_ <- true

let noalloc x = x.noalloc <- true

let termination x = x.termination <- true