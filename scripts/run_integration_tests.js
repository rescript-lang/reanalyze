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

  assertNotIncludes(output, "Parent is a dead module");
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
