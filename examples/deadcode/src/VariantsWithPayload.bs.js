// Generated by BUCKLESCRIPT, PLEASE EDIT WITH CARE


function testWithPayload(x) {
  return x;
}

function printVariantWithPayload(x) {
  if (typeof x === "string") {
    if (x === "a") {
      console.log("printVariantWithPayload: a");
    } else if (x === "b") {
      console.log("printVariantWithPayload: b");
    } else if (x === "Half") {
      console.log("printVariantWithPayload: Half");
    } else if (x === "True") {
      console.log("printVariantWithPayload: True");
    } else {
      console.log("printVariantWithPayload: Twenty");
    }
    return ;
  }
  var payload = x.VAL;
  console.log("printVariantWithPayload x:", payload.x, "y:", payload.y);
  
}

function testManyPayloads(x) {
  return x;
}

function printManyPayloads(x) {
  var variant = x.NAME;
  if (variant === "two") {
    var match = x.VAL;
    console.log("printManyPayloads two:", match[0], match[1]);
    return ;
  }
  if (variant === "three") {
    var payload = x.VAL;
    console.log("printManyPayloads x:", payload.x, "y:", payload.y);
    return ;
  }
  console.log("printManyPayloads one:", x.VAL);
  
}

function testSimpleVariant(x) {
  return x;
}

function testVariantWithPayloads(x) {
  return x;
}

function printVariantWithPayloads(x) {
  if (typeof x === "number") {
    console.log("printVariantWithPayloads", "A");
    return ;
  }
  switch (x.TAG | 0) {
    case /* B */0 :
        console.log("printVariantWithPayloads", "B(" + (String(x._0) + ")"));
        return ;
    case /* C */1 :
        console.log("printVariantWithPayloads", "C(" + (String(x._0) + (", " + (String(x._1) + ")"))));
        return ;
    case /* D */2 :
        var match = x._0;
        console.log("printVariantWithPayloads", "D((" + (String(match[0]) + (", " + (String(match[1]) + "))"))));
        return ;
    case /* E */3 :
        console.log("printVariantWithPayloads", "E(" + (String(x._0) + (", " + (x._1 + (", " + (String(x._2) + ")"))))));
        return ;
    
  }
}

function testVariant1Int(x) {
  return x;
}

function testVariant1Object(x) {
  return x;
}

export {
  testWithPayload ,
  printVariantWithPayload ,
  testManyPayloads ,
  printManyPayloads ,
  testSimpleVariant ,
  testVariantWithPayloads ,
  printVariantWithPayloads ,
  testVariant1Int ,
  testVariant1Object ,
  
}
/* No side effect */
