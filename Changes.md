# Unreleased

- Fix DCE false positives on case-insensitive file systems (macOS, Windows): a unit's `.cmt` was found under two spellings and treated as ambiguous, so exceptions raised across modules of a dune wrapped library were reported as never raised.
- Fix DCE false positives for type re-exports `type t = M.t = A | B` (OCaml 5.3+): constructors and labels are shared with the original type, also when `M` is a local module alias.
- Fix DCE false positives for types declared in a submodule of an interface (`module M : sig type t = A end`), which were not matched with their implementation.
- Fix false positive "optional argument is never used" reports on aliases and partial applications of functions with optional parameters (e.g. `let assert_equal = OUnit.assert_equal`), also when exported through an interface: they stand for the function they apply, and calls through them count for it. A binding stands for the applied function only when its optional parameters are the ones that function leaves (`let g = wrap f` with `wrap : ?x:_ -> 'a -> 'a` does not); `let g = f` always does, also with a constraint that names its type (`let g : fn = f`), and so does a nested application (`let p = 1 |> f ~x:1`, typed as `(f ~x:1) 1`). Each call through a partial application that stands for the function is a call of that function with the optional arguments the application passes (`let p = f ~x:1`); the application itself counts as a call only when nothing calls through `p`. A binding that does not stand for the applied function owns no optional parameters; a function among its arguments that has all of them may receive them (in `let g = wrap f`, calls through `g` may supply `f`'s).
- Fix false positive "optional argument is never used" reports for functions passed to a parameter declared as a function with optional parameters (e.g. `find (lookup : ?loc:_ -> _)` calling `lookup ~loc`), or as a named type (`type lookup = ?loc:int -> int -> int`).
- Limits of the optional-argument rules above: an alias that escapes (`ignore p`) counts as not called through, so with a chained alias (`let q = p ~y:2`) the arguments only the chain passes are reported as always supplied; an alias needs the applied function to be an identifier (`let q = (fun x -> x) p` does not stand for `p`, though `p` may receive what calls through `q` pass); a function passed directly to a callee that is not an identifier (`(fun h -> h ~loc:1 2) f`) is not credited; and calls through an alias of a functor parameter's value (`let g = M.f` in a functor body) count for every implementation of the parameter's signature, not only for the one the functor is applied to.
- Fix "optional argument" reports leaking between functions without optional parameters, which shared one mutable record, and "always supplied" reports for labels a function does not own.
- Fix optional-argument reports for functions whose type is named with an abbreviation (`type fn = ?x:int -> unit -> int`): calls through a value of type `fn` were not recorded, and a `val f : fn` in an interface hid all reports for the implementation. An alias `let g = f` is followed whatever its type shows, also when `f` is itself such a value (`let first : fn = plain`, `let second = first`).
- Support analyzing several build trees of one project together (e.g. two dune profiles): sources found only inside a build tree are read from it, and a unit compiled from the same source in several trees resolves to the copy in the consumer's tree. A source path that names different files in different trees is warned about, since their declarations cannot be told apart; so is a file in the current directory that differs from its copy in a tree, which means the build is out of date.
- Share parsed `.cmt` files between lookups instead of parsing them once per lookup directory, which reduces memory use on large projects.

- Fix false positives for values in functor bodies (and modules) constrained by a module type defined in another file, e.g. `module Make (K) : Gen.S with type key = K.t`. On OCaml 5.3+ declaration dependencies pointing at other compilation units are now resolved, and references to `val` items of a named module type are forwarded to the implementations satisfying it.

# 2.26.0

- Support OCaml 5.3, 5.4, and 5.5.

# 2.25.1

- Fix fatal error for OCaml 5.2.

# 2.25.0

- Support OCaml 5.2.

# 2.24.0

- Add `-native-build-target` option to explicitly specify a build target path for native OCaml projects.
- Support OCaml 5.1.

# 2.23.0

- Add command line option `-set-exit-code` to return an exit code (1) when at least one issue is reported.

# 2.22.0

- Add `-json` option to emit descriptions of issues, and actions to resolve them. For editor integration.
- Work around issue with location of variant cases in type declarations.

# 2.21.1

- Run `-config` by default
- Run `dce` when `"reanalyze"` is not present in `bsconfig.json`.

# 2.21.0

- Add support for `[@warning "-unused-value-declaration"]`.
- Don't report on dead values inside a function annotated `@dead`.
- Fix issue with punned record expressions in OCaml projects.
- Add command-line `-config` to read configuration settings under `"reanalyze"` in `bsconfig.json`.
  Example:

```json
{
  "reanalyze": {
    "analysis": ["dce", "exception"],
    "suppress": ["src/ToSuppress.res"],
    "unsuppress": ["this", "that"]
  }
}
```

- Allow lists and arrays as payloads e.g. for `@raises([A,B])`.
- Improve printing of exception annotations in error messages.
- Fix issue where the current file would be mistakenly reported dead and with empty name, when it contains an inner module which is dead and a toplevel exception.

# 2.19.0

- Don't report redundant optional arguments on functions annotated `@live`.

# 2.18.0

- Don't report unused optional arguments for functions annotated `@live` or `@genType`.
- Add support for `@live` or `dead` at toplevel in a type declaration. Equivalent to annotating all the record fields / variant cases.
- Turn off dead code reporting on externals by default. Add option `-externals` to turn back on.

# 2.17.0

- Give explicit error message for ast cases not implemented.

# 2.16.0

- Limited support for project with dune namespaces: when `Mylib.Foo` is not found try `Foo`.

# 2.15.0

- Exception analysis: also report on exceptions in toplevel expressions, not just variable bindings.
- Exception analysis: add support for Belt modules.
- Termination analysis: add support for try blocks.
- Termination analysis: add support for array creation.
- Termination analysis: add support for polymorphic variant creation.

# 2.14.0

- Fix issue where type dependencies could get lost if the last file processed is an interface file.
- Exception analysis: Bytes.sub_string throws.

# 2.13.0

- Don't report on module bindings coming from the type of first-class modules (see https://github.com/reason-association/reanalyze/issues/107).
- Fix issue where `emptyArray` was reported unused for lowercase components without children. (See https://github.com/reason-association/reanalyze/issues/85).

# 2.12.0

- Support OCaml 4.11 and 4.12.

# 2.11.0

- Exception Analysis: add basic support for module aliases (e.g. `module Array = Belt.Array`).

# 2.10.0

- Exception analysis: add support for inner modules.
- Exception analysis: correctly hide location of caught exceptions when other instances of the same exception are reported.
- Exception analysis: report on toplevel bindings of the form `let () = ...` and `let _ = ...`.

# 2.9.0

- Model `exit(...)` as raising a fictional exception called `exit`.
- Fix wording of error message for redundant exception annotation when the function raises nothing.

# 2.8.0

- Add DCE support for `.res` and `.resi` files with new bucklescript syntax.

# 2.7.0

- Fix `-live-paths` in bucklescript projects where absolute paths are used internally.
- Add command-line option `-exclude-paths`.
- Work around issue where `unsafe-expr`, generated by buklescript, was reported dead.

# 2.6.0

- In `-debug` mode, print `Sourcefile:path/to/File.re` for each `.cmt` loaded. This can be used to decide the current directory to call `renanalyze` from in `dune` projects.

# 2.5.0

- Turn on the checks for unused optional arguments, and dead module, in dce. No need for the `-experimental` flag anymore.

# 2.3.0

- DCE: add check Warning Redundant Optional Argument when an optional named argument is always supplied. Then there is no reason for it to be an optional argument.

# 2.2.0

- Fix issue in experimental analysis for unused optional named arguments where `foo(~x=?)` was not recognized.

# 2.1.0

- Add -experimental command-line to turn on experimental analyses.
- New analysis for unused optional named arguments, under the `-experimental` flag.
- New analysis for dead modules, under the `-experimental` flag.

# 1.16.0

- Only toplevel values are considered live when they have side-effects.
- Report a warning when a redundant @doesNotRaise annotation is used.

# 1.15.0

- Report analysis stats at the end.
- Issue dead exception reports as `Warning Dead Exception`.
- Dead exception: fix location position for `-write`.
- Add command-line options `-all` and `-all-cmt` to run all the analyses at once.

# 1.14.0

- CLI: rename `-blacklist` to `-suppress` and `-whitelist` to `-unsuppress`. This should clarify the semantics.
- When a generic exception is raised, as in `raise(exn)` report as if a specific exception of
  name `genericException` were raised. Can be suppressed just like real exceptions.
- Add new check for dead exceptions: that is exceptions defined but never raised directly or indirectly. An indirect raise (undecidable) is approximated by checking if the value is passed around in any way.

# 1.13.0

- Exception Analysis: model functions from Yojson.Basic.Util.
- Exception Analysis: fix issue with OCaml >= 4.08 where `raise` was not recognized.
- Exception Analysis: fix issue with OCaml >= 4.08 where models of the standard library were not recognized.

# 1.12.0

- Exception Analysis: print all the locations where a given exception is raised, not just one.
- DCE: rely on latest Bucklescritpt (7.3.2) and ReasonReact (0.8.0) to remove hack which fixes locations in code generated by the React PPX.

# 1.11.0

- Add command-line options `-blacklist` and `-whitelist` that apply to all the analyses.
  Example: `../reanalyze.exe -exception -blacklist src -whitelist src/Ex`
  will only show results for files `src/Ex*`.
  The analyses are not affected (e.g. transitively dead code), only the reporting is.
- Exception analysis: add support for `@doesNotRaise` to indicate that an expression does not raise any exceptions (to suppress possible analysis reports).
- Exception Analysis: add model for `Yojson.Basic.from_string`.

# 1.10.0

- Exception: Add warning when `raise` or `raise_notrace` are used not in a direct call.
- Exception: support `raise @@ Exn` and `Exn |> raise`.
- Exception: model `Js.Json`.
- Exception: model `bs-json`.

# 1.9.0

- Exception analysis: Model exceptions for `Array`, `Buffer`, `Bytes`, `Char`, `Filename`, `Hashtbl`, `Pervasives`, `Str`, `String`.

# 1.8.0

- First feature-complete exception analysis with `-exception` (bucklescript) and `-exception-cmt` for native.

# 1.7.0

- Early preview of exception analysis with `-exception` (bucklescript) and `-exception-cmt` for native.

# 1.6.0

- When file paths are implicit, e.g. `Foo.re` turn them into `./Foo.re` to help editor integration.
- Add command-line option `-debug` and discontinue environment variable `Debug`.
- Add command-line option `-write` and discontinue environment variable `Write`.

# 1.5.0

- Work around issue with flushing when printing first location.

# 1.4.0

- Always use OCaml's location format, which is picked up automatically by most tooling.
- Add warning emitted when a live item is annotated @dead.

# 1.3.0

- Add command-line option `-live-names this,that` to treat items `this` and `that` as globally live.
- Support `@warning "-32"` in addition `@ocaml.warning "-32"` to mean `@live`.
- Add command-line option `live-paths prefix/of/path1,prefix/of/path2` to treat all items in the path prefixes as live.

# 1.2.0

- Turn off reporting on `_` as it interferes with the `@deriving` ppx.
- Add option to report types dead only in the interface, now off by default.
- Support `@ocaml.warning "-32"` to mean `@live`.
- Capture dependencies between types in interface and implementation files.

# 1.1.0

- More robust detection of file names (don't rely on the name from the .cmt file).
- Add support for building with OCaml 4.08.

# 1.0.0

Initial release.
