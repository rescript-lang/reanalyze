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
    return output;
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

    // An interface-only provider can forward an explicit alias to a scanned
    // implementation, without importing that provider's implementation CMT.
    const interfaceOnly = path.join(root, "interface-only");
    compile(interfaceOnly, "source.ml", "exception Used = Not_found\nexception Unused = Not_found");
    compile(interfaceOnly, "wrapper.mli", "module Alias = Source");
    compile(interfaceOnly, "wrapper.ml", "module Alias = Source");
    compile(interfaceOnly, "use.ml", "let () = raise Wrapper.Alias.Used");
    const interfaceScan = path.join(interfaceOnly, "scan");
    fs.mkdirSync(interfaceScan);
    for (const filename of ["source.cmt", "wrapper.cmti", "use.cmt"]) {
      fs.copyFileSync(path.join(interfaceOnly, filename), path.join(interfaceScan, filename));
    }
    analyze(interfaceOnly, interfaceScan, ["source.Used"], ["source.Unused"]);

    // Unwrapped identifiers can infer forwarding children before a constraint
    // exposes more specific aliases. Retain those aliases without the provider.
    const unwrappedInclude = path.join(root, "unwrapped-include");
    compile(unwrappedInclude, "exn.ml", "exception Used = Not_found\nexception Unused = Not_found");
    compile(unwrappedInclude, "exports.ml", "module Nested = struct module Alias = Exn end");
    compile(unwrappedInclude, "constrained.ml",
      "include (Exports : sig module Nested : sig module Alias = Exn end end)");
    compile(unwrappedInclude, "use.ml", "let () = raise Constrained.Nested.Alias.Used");
    const includeScan = path.join(unwrappedInclude, "scan");
    fs.mkdirSync(includeScan);
    for (const filename of ["exn.cmt", "constrained.cmt", "use.cmt"]) {
      fs.copyFileSync(path.join(unwrappedInclude, filename), path.join(includeScan, filename));
    }
    analyze(unwrappedInclude, includeScan, ["exn.Used"], ["exn.Unused"]);

    // Re-entering a wrapper through B.A.X after A.X is finite, even though
    // the new field list ends with the entire previous field list.
    const growingWrapper = path.join(root, "growing-wrapper");
    fs.mkdirSync(growingWrapper);
    for (const [filename, source] of [
      ["dune-project", "(lang dune 2.0)\n(name growing_exception_wrapper)"],
      ["dune", "(executable (name main) (flags (:standard -w -a)))"],
      ["b.ml", "module A = struct module X = struct exception Used = Not_found exception Unused = Not_found end end"],
      ["a.ml", "module X = B.A.X"],
      ["main.ml", "let () = try raise A.X.Used with _ -> ()"],
    ]) fs.writeFileSync(path.join(growingWrapper, filename), source);
    child_process.execFileSync("dune", ["build", "--root", ".", "@check"],
      { cwd: growingWrapper, stdio: "pipe" });
    analyze(growingWrapper, "_build/default", ["b.A.X.Used"], ["b.A.X.Unused"]);

    // The scanner distinguishes identical sources built against different
    // dependencies. Exception resolution must retain both consumer contexts.
    const contexts = path.join(root, "contexts");
    compile(contexts, "left.ml", "exception Used = Not_found\nexception Unused = Not_found");
    compile(contexts, "right.ml", "exception Used = Not_found\nexception Unused = Not_found");
    compile(path.join(contexts, "a"), "provider.ml", "module Alias = Left", [contexts]);
    compile(path.join(contexts, "b"), "provider.ml", "module Alias = Right", [contexts]);
    const shared = path.join(contexts, "shared.ml");
    fs.writeFileSync(shared, "let () = raise Provider.Alias.Used");
    for (const dir of ["a", "b"]) {
      child_process.execFileSync("ocamlc", [
        "-bin-annot", "-I", dir, "-c", "-o", `${dir}/shared.cmo`, shared,
      ], { cwd: contexts, stdio: "pipe" });
    }
    const assertContexts = () => {
      const output = analyze(contexts, ".", ["left.Used", "right.Used"],
        ["left.Unused", "right.Unused"]);
      if ((output.match(/Scanning .*shared\.cmt /g) || []).length !== 2) {
        throw new Error(`Expected each exception consumer context once:\n${output}`);
      }
    };
    assertContexts();
    for (const dir of ["a", "b"]) {
      fs.mkdirSync(path.join(contexts, dir, "install"));
      for (const file of ["provider.cmt", "shared.cmt"]) {
        fs.copyFileSync(path.join(contexts, dir, file),
          path.join(contexts, dir, "install", file));
      }
    }
    assertContexts();

    // Ordered implicit opens can change a local alias target while leaving
    // the source and imported interfaces identical. Keep both lexical graphs.
    const opens = path.join(root, "ordered-open-contexts");
    for (const name of ["left", "right"]) {
      compile(opens, `${name}.ml`, "exception Used = Not_found\nexception Unused = Not_found");
    }
    compile(opens, "first.ml", "module Target = Left");
    compile(opens, "second.ml", "module Target = Right");
    const openedSource = path.join(opens, "shared.ml");
    fs.writeFileSync(openedSource,
      "let run () = let module Alias = Target in raise Alias.Used\nlet () = run ()");
    for (const [dir, names] of [["a", ["First", "Second"]], ["b", ["Second", "First"]]]) {
      fs.mkdirSync(path.join(opens, dir));
      child_process.execFileSync("ocamlc", [
        "-bin-annot", ...names.flatMap((name) => ["-open", name]),
        "-c", "-o", `${dir}/shared.cmo`, openedSource,
      ], { cwd: opens, stdio: "pipe" });
    }
    analyze(opens, ".", ["left.Used", "right.Used"], ["left.Unused", "right.Unused"]);

    // Identical provider sources can also have equal interface digests but
    // distinct imports. Without a matching sibling, do not choose either one.
    const ambiguous = path.join(root, "ambiguous-provider-contexts");
    compile(ambiguous, "left.ml", "exception Used = Not_found");
    compile(ambiguous, "right.ml", "exception Used = Not_found");
    compile(path.join(ambiguous, "a"), "provider.ml", "module Target = Left", [ambiguous]);
    compile(path.join(ambiguous, "b"), "provider.ml", "module Target = Right", [ambiguous]);
    const aliasSource = path.join(ambiguous, "shared.ml");
    fs.writeFileSync(aliasSource, "module Alias = Provider.Target");
    for (const dir of ["a", "b"]) {
      child_process.execFileSync("ocamlc", [
        "-bin-annot", "-I", dir, "-c", "-o", `${dir}/shared.cmo`, aliasSource,
      ], { cwd: ambiguous, stdio: "pipe" });
    }
    compile(ambiguous, "use.ml", "let () = raise Shared.Alias.Used", [path.join(ambiguous, "b")]);
    for (const reverse of [false, true]) {
      const scanRoot = path.join(ambiguous, `order-${reverse}`);
      for (const dir of ["a", "b", "consumer"]) fs.mkdirSync(path.join(scanRoot, dir), { recursive: true });
      for (const file of ["left.cmt", "right.cmt", "use.cmt"]) {
        fs.copyFileSync(path.join(ambiguous, file), path.join(scanRoot, "consumer", file));
      }
      for (const [from, to] of reverse ? [["a", "b"], ["b", "a"]] : [["a", "a"], ["b", "b"]]) {
        for (const file of ["provider.cmt", "shared.cmt"]) {
          fs.copyFileSync(path.join(ambiguous, from, file), path.join(scanRoot, to, file));
        }
      }
      analyze(ambiguous, scanRoot, [], ["left.Used", "right.Used"]);
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
