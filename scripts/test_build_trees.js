const child_process = require("child_process");
const fs = require("fs");
const os = require("os");
const path = require("path");

// One library built in two configurations (as dune does for two profiles or
// build directories), each with its own generated copy of a platform module,
// analyzed together from the source tree. Uses in either configuration keep
// a declaration live; sources found only inside a build tree (generated
// files) are read from that tree; and units compiled from one source in both
// trees resolve to the copy in the consumer's own tree (OCaml >= 5.3), also
// when it is in another directory of that tree, as with dune libraries.
module.exports = function testBuildTrees(reanalyzeFile) {
  const root = fs.mkdtempSync(path.join(os.tmpdir(), "reanalyze-build-trees-"));
  const write = (file, content) => {
    fs.mkdirSync(path.dirname(file), { recursive: true });
    fs.writeFileSync(file, content);
  };
  const sources = {
    "src/lib.ml": [
      "type mode = Native_only | Playground_only | Playground_through_reexport | Never_built",
      "let hash s = Platform.hash s",
      "let native_only () = Native_only",
      "let playground_only () = Playground_only",
      "let unused () = 0",
      "",
    ].join("\n"),
    "app/main.ml": "let () = ignore (Lib.hash \"a\"); ignore (Lib.native_only ())\n",
    "app/playground.ml": [
      "let () = ignore (Lib.hash \"a\"); ignore (Lib.playground_only ())",
      "type mode = Lib.mode = Native_only | Playground_only | Playground_through_reexport | Never_built",
      "let () = ignore (Playground_through_reexport : mode)",
      "",
    ].join("\n"),
  };
  const platforms = {
    native: "let hash (s : string) = Hashtbl.hash s\nlet native_unused = 1\n",
    // Different files under one name: their declarations are told apart by
    // position only, and reports read one of the files (hence the warning).
    browser: "let hash (s : string) = String.length s\n\nlet browser_unused = 2\n",
  };
  for (const [file, content] of Object.entries(sources)) {
    write(path.join(root, file), content);
  }
  const trees = {
    native: ["src/platform.ml", "src/lib.ml", "app/main.ml"],
    browser: ["src/platform.ml", "src/lib.ml", "app/playground.ml"],
  };
  for (const [tree, files] of Object.entries(trees)) {
    const dir = path.join(root, `_build_${tree}`);
    write(path.join(dir, "src/platform.ml"), platforms[tree]);
    for (const file of files.slice(1)) {
      write(path.join(dir, file), sources[file]);
    }
    for (const file of files) {
      child_process.execFileSync("ocamlc", [
        "-w", "-a", "-bin-annot", "-I", "src", "-c", file,
      ], { cwd: dir, stdio: "pipe" });
    }
  }
  const scan = path.join(root, "scan");
  fs.mkdirSync(scan);
  for (const tree of Object.keys(trees)) {
    fs.symlinkSync(path.join(root, `_build_${tree}`), path.join(scan, tree));
  }
  const run = child_process.spawnSync(reanalyzeFile, [
    "-ci", "-debug", "-dce-cmt", scan,
  ], { cwd: root, encoding: "utf8", maxBuffer: 64 * 1024 * 1024 });
  if (run.status !== 0) throw new Error(`build trees: reanalyze failed\n${run.stderr}`);
  const output = run.stdout;
  // The generated platform.ml differs between the trees: warned about once.
  const warnings = run.stderr.split("\n").filter((l) => l.startsWith("Warning: src/platform.ml differs"));
  if (warnings.length !== 1) {
    throw new Error(`build trees: expected one differing-source warning\n${run.stderr}`);
  }
  const expect = (text, present = true) => {
    if (output.includes(text) !== present) {
      throw new Error(
        `build trees: expected output ${present ? "" : "not "}to contain ${text}\n${output}`);
    }
  };
  for (const name of ["lib.+native_only", "lib.+playground_only", "lib.+hash"]) {
    expect(`Live Value +${name}:`);
    expect(`Dead Value +${name}:`, false);
  }
  expect("Dead Value +lib.+unused:");
  // The generated platform copies are scanned from their build trees.
  expect("Live Value +platform.+hash:");
  expect("Dead Value +platform.+native_unused:");
  expect("Dead Value +platform.+browser_unused:");

  // Constructed only in the browser tree, through a re-export: the original
  // is found in the browser copy of Lib, whose source is shared with the
  // native copy, but whose dependency context differs.
  const [major, minor] = child_process
    .execFileSync("ocamlc", ["-version"], { encoding: "utf8" })
    .trim().split(".").map(Number);
  if (major > 5 || (major === 5 && minor >= 3)) {
    expect("Live VariantCase +lib.mode.Playground_through_reexport:");
    expect("Dead VariantCase +lib.mode.Playground_through_reexport:", false);
  }
  expect("Dead VariantCase +lib.mode.Never_built:");
  fs.rmSync(root, { recursive: true, force: true });
};
