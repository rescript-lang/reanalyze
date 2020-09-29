// Generated by BUCKLESCRIPT, PLEASE EDIT WITH CARE

import * as Curry from "bs-platform/lib/es6/curry.js";
import * as Yojson from "./Yojson.bs.js";
import * as Caml_obj from "bs-platform/lib/es6/caml_obj.js";
import * as Caml_js_exceptions from "bs-platform/lib/es6/caml_js_exceptions.js";

function foo(x) {
  return Yojson.Basic.from_string(x);
}

function bar(str, json) {
  try {
    return Curry._2(Yojson.Basic.Util.member, str, json);
  }
  catch (raw_exn){
    var exn = Caml_js_exceptions.internalToOCamlException(raw_exn);
    if (exn.RE_EXN_ID === Yojson.Basic.Util.Type_error) {
      if (exn._1 === "a") {
        if (Caml_obj.caml_equal(exn._2, json)) {
          return json;
        }
        throw exn;
      }
      throw exn;
    }
    throw exn;
  }
}

function toString(x) {
  return Curry._1(Yojson.Basic.Util.to_string, x);
}

function toInt(x) {
  return Curry._1(Yojson.Basic.Util.to_int, x);
}

export {
  foo ,
  bar ,
  toString ,
  toInt ,
  
}
/* No side effect */
