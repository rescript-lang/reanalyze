// Generated by BUCKLESCRIPT, PLEASE EDIT WITH CARE

import * as OptArg from "./OptArg.bs.js";

console.log(OptArg.bar(undefined, 3, 3, 4));

function foo(xOpt, y) {
  var x = xOpt !== undefined ? xOpt : 3;
  return x + y | 0;
}

function bar(param) {
  var x = 12;
  return x + 3 | 0;
}

console.log(bar);

export {
  foo ,
  bar ,
  
}
/*  Not a pure module */
