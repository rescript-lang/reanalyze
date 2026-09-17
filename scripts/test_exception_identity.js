const child_process = require("child_process");
const fs = require("fs");
const os = require("os");
const path = require("path");

module.exports = function testExceptionIdentity(reanalyzeFile) {
  const root = fs.mkdtempSync(path.join(os.tmpdir(), "reanalyze-exception-identity-"));
  const compile = (cwd, filename, source, includes = []) => {
    fs.mkdirSync(cwd, { recursive: true });
    fs.writeFileSync(path.join(cwd, filename), source);
    child_process.execFileSync("ocamlc", [
      "-w", "-a", "-bin-annot", ...includes.flatMap((dir) => ["-I", dir]),
      "-c", path.join(cwd, filename),
    ], { cwd, stdio: "pipe" });
  };
  const analyze = (cwd, scanRoot, live, dead) => {
    const output = child_process.execFileSync(reanalyzeFile, [
      "-ci", "-debug", "-native-build-target", ".", "-dce-cmt", scanRoot,
    ], { cwd, encoding: "utf8" });
    for (const [state, names] of [["Live", live], ["Dead", dead]]) {
      for (const name of names) {
        const expected = `${state} Exception +${name}:`;
        if (!output.includes(expected)) {
          throw new Error(`${scanRoot}: expected ${expected}\n${output}`);
        }
        const opposite = `${state === "Live" ? "Dead" : "Live"} Exception +${name}:`;
        if (output.includes(opposite)) throw new Error(`${scanRoot}: ${opposite}\n${output}`);
      }
    }
  };
  try {
    const cases = [
      ["local", "", "module Left = Right\nlet () = raise Left.Used", ["right.Used"], ["left.Used"]],
      ["let-local", "", "let () = let module Left = Right in raise Left.Used", ["right.Used"], ["left.Used"]],
      ["shadow-alias", "include struct module Alias = Left end\nmodule Alias = Right", "let () = raise A.Alias.Used", ["right.Used"], ["left.Used"]],
      ["shadow-concrete", "include struct module Alias = Left end\nmodule Alias = struct exception Used = Not_found end", "let () = raise A.Alias.Used", ["a.Alias.Used"], ["left.Used", "right.Used"]],
      ["saved", "module Source = struct exception Used = Not_found end\ninclude struct module Alias = Source end\nmodule Saved = Alias\nmodule Alias = struct exception Used = Not_found end", "let () = raise A.Saved.Used", ["a.Source.Used"], ["a.Alias.Used", "left.Used", "right.Used"]],
      ["saved-and-replaced", "module Source = struct exception Used = Not_found end\ninclude struct module Alias = Source end\nmodule Saved = Alias\nmodule Alias = struct exception Used = Not_found end", "let () = (try raise A.Saved.Used with _ -> ()); raise A.Alias.Used", ["a.Source.Used", "a.Alias.Used"], ["left.Used", "right.Used"]],
    ];
    for (const [name, moduleSource, use, live, dead] of cases) {
      const cwd = path.join(root, name);
      compile(cwd, "left.ml", "exception Used = Not_found");
      compile(cwd, "right.ml", "exception Used = Not_found");
      compile(cwd, "a.ml", moduleSource);
      compile(cwd, "use.ml", use);
      analyze(cwd, ".", live, dead);
    }

    // The consumer imports one Foo, and Foo in turn imports its own Target.
    // A same-named sibling with a conflicting digest must never win, even
    // when the matching provider is absent from the scan.
    const cwd = path.join(root, "digests");
    const one = path.join(cwd, "one");
    const two = path.join(cwd, "two");
    const consumer = path.join(cwd, "consumer");
    compile(cwd, "left.ml", "exception Used = Not_found");
    compile(cwd, "right.ml", "exception Used = Not_found");
    compile(one, "target.ml", "module Inner = Left", [cwd]);
    compile(two, "target.ml", "module Inner = Right", [cwd]);
    compile(one, "foo.ml", "module Alias = Target.Inner", [cwd]);
    compile(two, "foo.ml", "module Alias = Right", [cwd]);
    compile(consumer, "use.ml", "let () = raise Foo.Alias.Used", [one, cwd]);
    const common = [path.join(cwd, "left.cmt"), path.join(cwd, "right.cmt"), path.join(consumer, "use.cmt")];
    const copy = (scanRoot, dir, files) => {
      const destination = path.join(scanRoot, dir);
      fs.mkdirSync(destination, { recursive: true });
      for (const file of files) fs.copyFileSync(file, path.join(destination, path.basename(file)));
    };
    for (const [name, matchingFoo, matchingTarget, reverse] of [
      ["forward", true, true, false],
      ["reverse", true, true, true],
      ["missing-foo", false, true, false],
      ["missing-target", true, false, false],
    ]) {
      const scanRoot = path.join(cwd, name);
      copy(scanRoot, "consumer", common);
      if (matchingFoo) copy(scanRoot, reverse ? "z" : "a", [path.join(one, "foo.cmt")]);
      copy(scanRoot, reverse ? "a" : "z", [path.join(two, "foo.cmt")]);
      if (matchingTarget) copy(scanRoot, reverse ? "b" : "y", [path.join(one, "target.cmt")]);
      copy(scanRoot, reverse ? "y" : "b", [path.join(two, "target.cmt")]);
      analyze(cwd, scanRoot,
        matchingFoo && matchingTarget ? ["left.Used"] : [],
        matchingFoo && matchingTarget ? ["right.Used"] : ["left.Used", "right.Used"]);
    }
    console.log("Exception binding and import identity assertions passed");
  } finally {
    fs.rmSync(root, { recursive: true, force: true });
  }
};
