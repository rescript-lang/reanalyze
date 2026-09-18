const child_process = require("child_process");
const fs = require("fs");
const path = require("path");

module.exports = function testExceptionIncludes(root, compile, analyze) {
  const exceptions = "exception Used = Not_found\nexception Unused = Not_found\n";
  const signature = "sig exception Used exception Unused end";
  const cases = [
    ["direct", "include Source"],
    ["chained", "include Relay"],
    ["constrained", `include (Source : ${signature})`],
    ["named-constraint", `module type S = ${signature}\ninclude (Source : S)`],
    ["nested", "module Nested = struct include Source end", "Wrapper.Nested.Used"],
    ["nested-constraint", `include (struct module Nested = Source end : sig module Nested : ${signature} end)`, "Wrapper.Nested.Used"],
    ["local", `module Local = struct ${exceptions}end\ninclude Local`, "Wrapper.Used", ["wrapper.Local.Used"], ["source.Used", "other.Used", "wrapper.Local.Unused"]],
    ["anonymous", `include struct ${exceptions}end`, "Wrapper.Used", ["wrapper.Used"], ["source.Used", "other.Used", "wrapper.Unused"]],
    ["anonymous-nested", "include struct include Source end"],
    ["local-alias", "module Alias = Source\ninclude Alias"],
    ["captured-alias", "include struct module Target = Source end\nmodule Saved = Target\nmodule Target = Other\ninclude Saved"],
    ["captured-module", "include struct module M = struct include Source end end\nmodule Saved = M\nmodule M = struct include Other end", "Wrapper.Saved.Used"],
    ["last-include", "include Source\ninclude Other", "Wrapper.Used", ["other.Used"], ["source.Used"]],
    ["rebound", "include Source\nexception Used = Other.Used", "Wrapper.Used", ["wrapper.Used"], ["source.Used"]],
    ["let-local", "include Source", "(let module Local = struct include Wrapper end in Local.Used)"],
    ["captured-exception", "include Source\nlet saved () = raise Used\ninclude Other", "(Wrapper.saved (); Wrapper.Used)", ["source.Used", "other.Used"], []],
    ["captured-before-rebind", "include Source\nlet saved () = raise Used\nexception Used = Other.Used", "(Wrapper.saved (); Wrapper.Used)", ["source.Used", "wrapper.Used"], []],
    ["captured-constrained", `include (Source : ${signature})\nlet saved () = raise Used\ninclude Other`, "(Wrapper.saved (); Not_found)"],
    ["captured-constrained-both", `include struct include (Source : ${signature}) end\nlet saved () = raise Used\ninclude Other`, "(Wrapper.saved (); Wrapper.Used)", ["source.Used", "other.Used"], []],
    ["qualified-constrained-local", `module M = struct include (Source : ${signature}) end\nlet saved () = raise M.Used`, "(Wrapper.saved (); Not_found)"],
    ["local-constructor", "include Source\nlet saved () = raise Used", "(Wrapper.saved (); Not_found)"],
    ["recursive", `module rec A : ${signature} = struct include B end\nand B : ${signature} = struct include Source end\ninclude A`],
    ["functor", `module F () = struct ${exceptions}end\ninclude F ()`, "Wrapper.Used", ["wrapper.F.Used"], ["wrapper.F.Unused", "source.Used", "other.Used"]],
    ["unused-include", "include Source", "Not_found", [], ["source.Used", "other.Used"]],
    // Exception usage counts constructor references even in an unused function.
    ["unused-function", "include Source\nlet dead () = raise Used", "Not_found"],
    ["unused-function-qualified", "include Source\nlet dead () = raise Source.Used", "Not_found"],
  ];
  for (const [name, wrapper, use = "Wrapper.Used", live = ["source.Used"], dead = ["other.Used"]] of cases) {
    const cwd = path.join(root, "includes", name);
    compile(cwd, "source.ml", exceptions);
    compile(cwd, "other.ml", exceptions);
    compile(cwd, "relay.ml", "include Source");
    compile(cwd, "wrapper.ml", wrapper);
    compile(cwd, "use.ml", `let () = raise ${use}`);
    analyze(cwd, ".", live, [...dead, "source.Unused", "other.Unused"]);
  }

  // Dune's generated compilation-unit wrapper adds another alias hop.
  const wrapped = path.join(root, "wrapped-includes");
  fs.mkdirSync(wrapped);
  for (const [filename, content] of [
    ["dune-project", "(lang dune 2.0)\n(name included_exception)"],
    ["dune", "(library (name included_exception) (modules source wrapper))\n(executable (name main) (modules main) (libraries included_exception))"],
    ["source.ml", exceptions], ["wrapper.ml", "include Source"],
    ["main.ml", "let () = raise Included_exception.Wrapper.Used"],
  ]) fs.writeFileSync(path.join(wrapped, filename), content);
  child_process.execFileSync("dune", ["build", "@check"], { cwd: wrapped, stdio: "pipe" });
  analyze(wrapped, "_build", ["source.Used"], ["source.Unused"]);

  // Include forwarding must preserve provider selection across artifact layouts.
  // Remove the build originals before analyzing from a neutral working directory.
  const fixture = path.join(root, "include-layouts");
  const build = path.join(fixture, "build");
  const alternate = path.join(fixture, "alternate");
  const neutral = path.join(fixture, "neutral");
  compile(build, "source.ml", exceptions);
  compile(build, "wrapper.mli", "include module type of Source");
  compile(build, "wrapper.ml", "include Source");
  compile(build, "use.ml", "let () = raise Wrapper.Used");
  fs.mkdirSync(alternate);
  fs.copyFileSync(path.join(build, "wrapper.cmi"), path.join(alternate, "wrapper.cmi"));
  // An explicit interface gives these distinct implementations the same digest.
  fs.writeFileSync(path.join(alternate, "wrapper.mli"), "include module type of Source");
  compile(alternate, "wrapper.ml", "include Source\nlet unused = ()", [build]);
  fs.mkdirSync(neutral);
  const layouts = [
    ["colocated", "one", "one", "one"],
    ["split", "api", "objects", "consumer"],
    ["beside-interface", "api", "objects", "api"],
    ["beside-implementation", "api", "objects", "objects"],
    ["copies", "api", "objects", "consumer"],
    ["competing", "api", "objects", "consumer"],
    ["missing-wrapper", "api", "objects", "consumer"],
  ];
  const copy = (scan, dir, source) => {
    const destination = path.join(scan, dir);
    fs.mkdirSync(destination, { recursive: true });
    fs.copyFileSync(source, path.join(destination, path.basename(source)));
  };
  for (const [name, api, objects, consumer] of layouts) {
    const scan = path.join(fixture, name);
    for (const prefix of name === "copies" ? ["", "install"] : [""]) {
      for (const [filename, dir] of [
        ["wrapper.cmti", api], ["wrapper.cmt", objects],
        ["source.cmt", consumer], ["use.cmt", consumer],
      ]) {
        if (name === "missing-wrapper" && filename.startsWith("wrapper.")) continue;
        copy(scan, path.join(prefix, dir), path.join(build, filename));
      }
    }
    if (name === "competing") copy(scan, "other", path.join(alternate, "wrapper.cmt"));
  }
  for (const dir of [build, alternate]) {
    for (const filename of fs.readdirSync(dir)) {
      if (/\.(cmt|cmti|cmi|cmo)$/.test(filename)) fs.unlinkSync(path.join(dir, filename));
    }
  }
  for (const [name] of layouts) {
    const unresolved = name === "competing" || name === "missing-wrapper";
    analyze(neutral, path.join(fixture, name), unresolved ? [] : ["source.Used"],
      unresolved ? ["source.Used", "source.Unused"] : ["source.Unused"]);
  }

  // Resolve each include using its own recorded imports. A same-named provider
  // with another digest must not stand in for a missing dependency.
  const digests = path.join(root, "include-digests");
  const one = path.join(digests, "one");
  const two = path.join(digests, "two");
  const consumer = path.join(digests, "consumer");
  compile(digests, "left.ml", exceptions);
  compile(digests, "right.ml", exceptions);
  compile(one, "source.ml", "include Left\nlet marker = 1", [digests]);
  compile(two, "source.ml", "include Right\nlet marker = true", [digests]);
  compile(one, "wrapper.ml", "include Source", [digests]);
  compile(two, "wrapper.ml", "include Source", [digests]);
  compile(consumer, "use.ml", "let () = raise Wrapper.Used", [one, digests]);
  const layoutsWithDigests = [
    ["forward", true, true, false],
    ["reverse", true, true, true],
    ["missing-wrapper", false, true, false],
    ["missing-source", true, false, false],
  ];
  for (const [name, wrapper, source, reverse] of layoutsWithDigests) {
    const scan = path.join(digests, name);
    for (const filename of ["left.cmt", "right.cmt"]) copy(scan, "consumer", path.join(digests, filename));
    copy(scan, "consumer", path.join(consumer, "use.cmt"));
    if (wrapper) copy(scan, reverse ? "z" : "a", path.join(one, "wrapper.cmt"));
    copy(scan, reverse ? "a" : "z", path.join(two, "wrapper.cmt"));
    if (source) copy(scan, reverse ? "b" : "y", path.join(one, "source.cmt"));
    copy(scan, reverse ? "y" : "b", path.join(two, "source.cmt"));
  }
  for (const dir of [digests, one, two, consumer]) {
    for (const filename of fs.readdirSync(dir)) {
      if (/\.(cmt|cmti|cmi|cmo)$/.test(filename)) fs.unlinkSync(path.join(dir, filename));
    }
  }
  for (const [name, wrapper, source] of layoutsWithDigests) {
    analyze(neutral, path.join(digests, name), wrapper && source ? ["left.Used"] : [],
      ["left.Unused", "right.Unused", "right.Used", ...(!wrapper || !source ? ["left.Used"] : [])]);
  }
};
