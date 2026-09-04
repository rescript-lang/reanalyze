> [!WARNING]
> This repository contains the OCaml version of reanalyze. The ReScript version is being developed inside the [rescript](https://github.com/rescript-lang/rescript/tree/master/analysis/reanalyze) monorepo.

# reanalyze

Program analysis for OCaml projects built with dune:

- Globally dead values, redundant optional arguments, dead modules, dead types (records and variants).
- Exception analysis.
- Termination.

## Expectations

Early release. While the core functionality is reasonably stable, the CLI and annotations are subject to change. However, this is a tiny surface at the moment.

## Use

The rest of this document describes the dead code analysis.
For the [Exception Analysis](EXCEPTION.md), build instructions are the same, and the command-line invocation is different.

Build and run on existing projects using the Build and Try instructions below. The analysis uses `.cmt[i]` files which are generated during compilation, so should be run _after_ building your project. Remember to rebuild the project before running again.

### CLI

```sh
# dead code analysis
reanalyze.exe -dce-cmt root/containing/cmt/files

# exception analysis
reanalyze.exe -exception-cmt root/containing/cmt/files
```

Subdirectories are scanned recursively looking for `.cmt[i]` files.

The requirement is that the _current_ directory is where file paths start from. So if the file path seen by the compiler is relative `src/core/version.ml` then the current directory should contain `src` as a subdirectory. The analysis only reports on existing files, so getting this wrong means no reporting.

### DCE reports

The dead code analysis reports on globally dead values, redundant optional arguments, dead modules, dead types (records and variants).

A value `x` is dead if it is never used, or if it is used by a value which itself is dead (transitivity). At the top level, function calls such as `print_endline x`, or other expressions that might cause side effects, keep value `x` live.

An optional argument `?argName` to a function is redundant if all the calls to the function supply the argument, or if no call does.

A module is considered dead if all the elements defined it in are dead.

The type analysis repots on variant cases, and record labels.

- A variant case `| A of int` is dead if a value such as `A 3` is never constructed. But it can be deconstructed via pattern matching  `| A n -> ...` or checked for equality `x = A 3` without making the case `A` live.

- A record label `x` in `type r = {x: int; y: int}` is dead if it is never read (by direct access `r.x` or pattern matching `| {x = n; y = m} -> ...`). However, creating a value `let r = {x = 3; y = 4}` does not make `x` and `y` live.
Note that reading a value `r` does not make `r.x` or `r.y` live.

While dead values can be removed automatically (see below), dead types require a bit more work. A dead variant case requires changing the type definition, and the various accesses to it. A dead record label requires changing the type definition, and removing the label from any expressions that create a value of that type.

### DCE: controlling reports with Annotations

The dead code analysis supports 2 annotations:

- `[@dead]` suppresses reporting on the value/type, but can also be used to force the analysis to consider a value as dead. Typically used to acknowledge cases of dead code you are not planning to address right now, but can be searched easily later.

- `[@live]` tells the analysis that the value should be considered live, even though it might appear to be dead. This is typically used in case of FFI, or other indirect ways to access values, that the analysis cannot see.

The main difference between `[@dead]` and `[@live]` is the transitive behaviour: `[@dead]` values don't keep alive values they use, while `[@live]` values do.

Annotations attach to the definition, as in `let[@live] x = ...`. Several examples can be found in
[`examples/deadcode/src/Annotations.ml`](examples/deadcode/src/Annotations.ml)

## Command-line Interface

### CLI -suppress
Takes a comma-separated list of path-prefixes. Don't report on files whose path has a prefix in the list (but still use them for analysis).

```sh
reanalyze.exe -suppress one/path,another/path
```

### CLI -unsuppress

Takes a comma-separated list of path-prefixes. Report on files whose path has a prefix in the list, overriding `-suppress` (no-op if `-suppress` is not specified).

```sh
reanalyze.exe -unsuppress one/path,another/path/File.ml
```

### CLI -debug

Print debug information during the analysis

```sh
reanalyze.exe -debug ...
```

### Add annotations automatically

This overwrites your source files automatically with dead code annotations:

```sh
reanalyze.exe -write ...
```

### CLI -live-names

This automatically annotates `[@live]` all the items called `foo` or `bar`:

```sh
-live-names foo,bar
```

### CLI -live-paths

This automatically annotates `[@live]` all the items in file `Hello.ml`:

```sh
-live-paths Hello.ml
```

This automatically annotates `[@live]` all the items in the `src/test` and `tmp` folders:

```sh
-live-paths src/test,tmp
```

### CLI -native-build-target

If a native project uses code generation and emit the generated files only in the build directory, reanalyze may not be able to locate them.
This is due to the paths being not relative to the project root directory.
An example of it can be caused by using tools like `ocamlyacc`.

For example, you might want to set `_build/default` for projects that use the default dune build target:
```sh
-native-build-target _build/default
```

## Build From Sources

```sh
opam install dune
dune build
# _build/default/src/Reanalyze.exe
```

## Try it

Make sure that `dune` builds both `.cmt` and `.cmti` files by enabling bytecode compilation. This is normally done by adding `(modes byte exe)` to the `executable` stanza in your dune file (see https://github.com/ocaml/dune/issues/3182):

This project is itself written in OCaml and can be analyzed as follows.
```sh
dune build
./_build/default/src/Reanalyze.exe -dce-cmt _build
```
