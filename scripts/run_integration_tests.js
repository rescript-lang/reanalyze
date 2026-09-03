const child_process = require("child_process");
const path = require("path");
const pjson = require("../package.json");

const exampleDirNames = ["deadcode", "termination"];
const exampleDirPaths = exampleDirNames.map((exampleName) =>
  path.join(__dirname, "..", "examples", exampleName)
);

const isWindows = /^win/i.test(process.platform);
const reanalyzeFile = path.join(__dirname, "../_build/default/src/Reanalyze.exe");

function cleanBuildExamples() {
  for (let i = 0; i < exampleDirPaths.length; i++) {
    const cwd = exampleDirPaths[i];
    console.log(`${cwd}: npm run clean && npm run build`);

    const shell = isWindows ? true : false;
    child_process.execFileSync("npm", ["run", "clean"], {
      cwd,
      shell,
      stdio: [0, 1, 2],
    });
    child_process.execFileSync("npm", ["run", "build"], {
      cwd,
      shell,
      stdio: [0, 1, 2],
    });
    child_process.execFileSync("npm", ["run", "analyze"], {
      cwd,
      shell,
      stdio: [0, 1, 2],
    });
  }
}

function checkDiff() {
  exampleDirNames.forEach((example) => {
    const exampleDir = path.join(path.join("examples", example), "src");
    console.log(`Checking for changes in '${exampleDir}'`);

    const output = child_process.execFileSync(
      "git",
      ["diff", "--", exampleDir + "/"],
      {
        encoding: "utf8",
      }
    );

    if (output.length > 0) {
      throw new Error(
        `Changed files detected in path '${exampleDir}'! Make sure reanalyze is emitting the right code and commit the files to git` +
          "\n" +
          output +
          "\n"
      );
    }
  });
}

function assertIncludes(output, expected) {
  if (!output.includes(expected)) {
    throw new Error(`Expected regression output to contain:\n${expected}`);
  }
}

function assertNotIncludes(output, unexpected) {
  if (output.includes(unexpected)) {
    throw new Error(`Regression output unexpectedly contained:\n${unexpected}`);
  }
}

function ocamlVersionAtLeast(major, minor) {
  const version = child_process
    .execFileSync("ocamlc", ["-version"], { encoding: "utf8" })
    .trim();
  const [actualMajor, actualMinor] = version.split(".").map(Number);
  return (
    actualMajor > major || (actualMajor === major && actualMinor >= minor)
  );
}

function runRegressionTests() {
  const cwd = path.join(__dirname, "..", "examples", "regression");
  const cmtDir = "_build/default/src/.regression_fixture.objs/byte";

  console.log(`${cwd}: dune clean && dune build`);
  child_process.execFileSync("dune", ["clean", "--root", "."], {
    cwd,
    stdio: [0, 1, 2],
  });
  child_process.execFileSync("dune", ["build", "--root", "."], {
    cwd,
    stdio: [0, 1, 2],
  });

  console.log(`${cwd}: reanalyze regression assertions`);
  const output = child_process.execFileSync(
    reanalyzeFile,
    ["-ci", "-debug", "-native-build-target", ".", "-dce-cmt", cmtDir],
    {
      cwd,
      encoding: "utf8",
    }
  );

  assertIncludes(output, "+definitely_dead is never used");
  assertIncludes(output, "Source:src/Generated_source.ml");
  assertIncludes(output, "Live Value +Functor_argument.Ordered.+compare");
  assertIncludes(output, "Dead Value +Functor_argument.Ordered.+unused");
  assertIncludes(output, "Live Value +Functor_argument.Anonymous_set.+compare");
  assertIncludes(output, "Dead Value +Functor_argument.Anonymous_set.+unused");
  assertIncludes(output, "Live Value +Local_side_effects.+_info");
  assertIncludes(output, "Live Value +Local_side_effects.+process");
  assertIncludes(output, "Live Value +Local_side_effects.+register");

  // A call through one functor instance must never mark the used
  // implementation dead.
  assertIncludes(output, "Live Value +Shared_signature_used.Make.+f");
  assertNotIncludes(output, "Dead Value +Shared_signature_used.Make.+f");
  assertIncludes(output, "Live Value +Shared_signature_arg.Chosen.+f");
  assertNotIncludes(output, "Dead Value +Shared_signature_arg.Chosen.+f");
  assertIncludes(output, "Live Value +Shared_signature_arg.Local_used.+f");
  assertNotIncludes(output, "Dead Value +Shared_signature_arg.Local_used.+f");
  // A call through a functor parameter is credited to the actual argument
  // (conservatively, to every implementation of the item, before OCaml 5.3):
  // x must never be reported unused.
  assertNotIncludes(
    output,
    "optional argument x of function Opt_chosen.+g is never used"
  );
  // Arguments wrapped in a constraint by a named module type are still used.
  assertIncludes(output, "Live Value +Shared_signature_arg.Chosen2.+f");
  assertNotIncludes(output, "Dead Value +Shared_signature_arg.Chosen2.+f");
  assertNotIncludes(output, "Dead Value +Shared_signature_arg.Opt_constrained.+g");
  // Precise attribution through a shared named module type relies on shape
  // reduction of identifier occurrences, available from OCaml 5.3. Earlier
  // versions conservatively keep every implementation of the item live.
  if (ocamlVersionAtLeast(5, 3)) {
    assertIncludes(output, "Dead Value +Shared_signature_unused.Make.+f");
    assertNotIncludes(output, "Live Value +Shared_signature_unused.Make.+f");
    assertIncludes(output, "Dead Value +Shared_signature_arg.Ignored.+f");
    assertNotIncludes(output, "Live Value +Shared_signature_arg.Ignored.+f");
    assertIncludes(output, "Dead Value +Shared_signature_arg.Local_unused.+f");
    assertNotIncludes(output, "Live Value +Shared_signature_arg.Local_unused.+f");
    // A call through a functor parameter supplying ?x must not be attributed
    // to other implementations of the module type item.
    assertIncludes(
      output,
      "optional argument x of function Opt_direct.+g is never used"
    );
    // ... and is credited precisely, including through a constraint, for an
    // inline functor, and for a functor with a whole-functor signature.
    assertIncludes(
      output,
      "optional argument x of function Opt_chosen.+g is always supplied"
    );
    assertIncludes(
      output,
      "optional argument x of function Opt_sigfun.+g is always supplied"
    );
    // ... through a named partial application, and for a let-module functor.
    assertIncludes(
      output,
      "optional argument x of function Opt_partial.+g is always supplied"
    );
    assertIncludes(
      output,
      "optional argument x of function Opt_letmodule.+g is always supplied"
    );
    // ... through an alias of the parameter, and for a recursive functor. The
    // aliased call must not leak to another implementation.
    assertIncludes(
      output,
      "optional argument x of function Opt_alias.+g is always supplied"
    );
    assertIncludes(
      output,
      "optional argument x of function Opt_alias_other.+g is never used"
    );
    assertIncludes(
      output,
      "optional argument x of function Opt_rec.+g is always supplied"
    );
    assertIncludes(
      output,
      "optional argument x of function Opt_constrained.+g is always supplied"
    );
    assertIncludes(
      output,
      "optional argument x of function Opt_inline.+g is always supplied"
    );
    assertIncludes(output, "Dead Value +Shared_signature_arg.Ignored2.+f");
  }

  assertNotIncludes(output, "Parent is a dead module");
  assertNotIncludes(output, "Dead Value +Functor_argument.Ordered.+compare");
  assertNotIncludes(output, "Live Value +Functor_argument.Ordered.+unused");
  assertNotIncludes(output, "Dead Value +Functor_argument.Anonymous_set.+compare");
  assertNotIncludes(output, "Live Value +Functor_argument.Anonymous_set.+unused");
  assertNotIncludes(output, "Dead Value +Local_side_effects.+_info");
  assertNotIncludes(output, "Dead Value +Local_side_effects.+process");
  assertNotIncludes(output, "Dead Value +Local_side_effects.+register");
}

function checkSetup() {
  console.log("Checking if --version outputs the right version");
  let output;

  try {
    output = child_process.execSync(`${reanalyzeFile} --version`, {
      shell: isWindows,
      encoding: "utf8",
    });
  } catch (e) {
    throw new Error(
      `reanalyze --version caused an unexpected error: ${e.message}`
    );
  }

  const stripNewlines = (str = "") => str.replace(/[\n\r]+/g, "");

  if (output.indexOf(pjson.version) === -1) {
    throw new Error(
      path.basename(reanalyzeFile) +
        ` --version doesn't contain the version number of package.json` +
        `("${stripNewlines(output)}" should contain ${pjson.version})` +
        `- Run \`node scripts/bump_version_module.js\` and rebuild to sync version numbers`
    );
  }
}

function main() {
  try {
    checkSetup();
    cleanBuildExamples();
    runRegressionTests();
    checkDiff();

    console.log("Test successful!");
  } catch (e) {
    console.error(`Test failed unexpectedly: ${e.message}`);
    console.error(e);
    process.exit(1);
  }
}

main();
