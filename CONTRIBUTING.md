# Development

## Build reanalyze

Assumes opam with OCaml 4.14 or later.

```
opam install dune cppo
dune build
# _build/default/src/Reanalyze.exe
```

## Test reanalyze

The tests are dune cram tests in `test/`, over the fixture projects in
`examples/`:

```
dune test
# After an intended change of output, review the diff and accept it with
dune promote
```

## Releases (for Maintainers)

1. In a pull request, set the new version in `src/Version.ml`, update
   `test/version.t` to match (`dune test` and `dune promote`), and rename the
   `# Unreleased` heading of `Changes.md` to the version. Raise the OCaml
   bounds in `reanalyze.opam` if needed.
2. After merging, tag the merge commit on master and push the tag:

   ```
   git tag -a vX.Y.Z -m "Version X.Y.Z"
   git push origin vX.Y.Z
   ```

3. Create a GitHub release from the tag, with the `Changes.md` section as
   release notes.
4. Publish to opam: with [opam-publish](https://github.com/ocaml-opam/opam-publish)
   (`opam install opam-publish`), run `opam publish` in a checkout of the tag.
   It opens a pull request on
   [opam-repository](https://github.com/ocaml/opam-repository) adding the
   package with the tag's source archive and checksums.
