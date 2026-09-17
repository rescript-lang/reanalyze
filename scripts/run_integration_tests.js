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
      // The debug output lists every reference; before OCaml 5.3 references
      // through module type items fan out to every implementation.
      maxBuffer: 256 * 1024 * 1024,
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
  // A parameter access must not suppress an ordinary access from the same
  // binding, regardless of which occurrence the mapper visits first.
  for (const order of ["Parameter_first", "Ordinary_first"]) {
    assertIncludes(output, `Live Value +Reference_order.${order}.Used.+f`);
    assertNotIncludes(output, `Dead Value +Reference_order.${order}.Used.+f`);
  }
  // A call through a functor parameter is credited to the actual argument
  // (conservatively, to every implementation of the item, before OCaml 5.3):
  // x must never be reported unused.
  assertNotIncludes(
    output,
    "optional argument x of function Opt_chosen.+g is never used"
  );
  // Arguments wrapped in a constraint by a named module type are still used.
  assertIncludes(output, "Live Value +Shared_signature_arg.Chosen2.+f");
  // Arguments of generative functors and applied arguments are used.
  assertIncludes(output, "Live Value +Shared_signature_arg.Opt_unit_first.+g");
  assertIncludes(output, "Live Value +Shared_signature_arg.Opt_unit_last.+g");
  assertIncludes(output, "Live Value +Shared_signature_arg.Mk_o.+g");
  assertIncludes(output, "Live Value +Shared_signature_arg.Fwd_used.+f");
  assertIncludes(output, "Live Value +Shared_signature_arg.Applied_struct.+g");
  assertIncludes(output, "Live Value +Higher_order.Opt_ho.+g");
  assertIncludes(output, "Live Value +Higher_order.Opt_fc.+g");
  assertIncludes(output, "Live Value +Higher_order.P_esc.+h");
  assertIncludes(output, "Live Value +Higher_order.Id_used.+f");
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
    // Argument constrained by an alias of the module type; a functor
    // forwarding its parameter to another functor; include of the parameter.
    assertIncludes(output, "Live Value +Shared_signature_arg.Chosen3.+f");
    assertIncludes(output, "Dead Value +Shared_signature_arg.Ignored3.+f");
    assertIncludes(output, "Live Value +Shared_signature_arg.Chosen4.+f");
    assertIncludes(output, "Dead Value +Shared_signature_arg.Ignored4.+f");
    assertIncludes(
      output,
      "optional argument x of function Opt_outer.+g is always supplied"
    );
    assertIncludes(
      output,
      "optional argument x of function Opt_incl.+g is always supplied"
    );
    assertIncludes(
      output,
      "optional argument x of function Opt_incl_other.+g is never used"
    );
    // A module type declared inside a module.
    assertIncludes(output, "Live Value +Nested_module_type.Outer.Used.+f");
    assertIncludes(output, "Dead Value +Nested_module_type.Outer.Unused.+f");
    // let-module alias of a functor; module type aliases rooted at a local
    // module and shadowing a same-named module type.
    assertIncludes(
      output,
      "optional argument x of function Opt_letalias.+g is always supplied"
    );
    assertIncludes(output, "Live Value +Shared_signature_arg.Use_t.+h");
    assertIncludes(output, "Live Value +Shared_signature_arg.Shadow.Use3.+k");
    // A nested module of the parameter constrained by a named module type.
    assertIncludes(output, "Live Value +Shared_signature_arg.Nested_arg.N.+g");
    assertIncludes(
      output,
      "optional argument x of function Nested_arg.N.+g is always supplied"
    );
    assertIncludes(
      output,
      "optional argument x of function Nested_other.N.+g is never used"
    );
    // Ten forwarding functors; modules inside a functor body; an alias of a
    // functor defined in another file; a module type in an included signature.
    assertIncludes(
      output,
      "optional argument x of function Opt_chain.+g is always supplied"
    );
    assertIncludes(
      output,
      "Dead Value +Shared_signature_arg.Apply_in_body.Ignored_in.+f"
    );
    assertIncludes(
      output,
      "Live Value +Shared_signature_arg.Apply_in_body.Chosen_in.+f"
    );
    assertIncludes(
      output,
      "optional argument x of function Opt_cross.+g is always supplied"
    );
    assertIncludes(output, "Live Value +Included_sig.M.+f");
    // A module type nested in a with-constrained signature; nine aliases.
    assertIncludes(output, "Live Value +Included_sig.W.X.+f");
    assertIncludes(
      output,
      "optional argument x of function Opt_alias9.+g is always supplied"
    );
    // A nested functor applied through Outer (A).Inner; a recursive alias.
    assertIncludes(
      output,
      "optional argument x of function Opt_ext.+g is always supplied"
    );
    assertIncludes(
      output,
      "optional argument x of function Opt_rec_alias.+g is always supplied"
    );
    // A recursive alias of the parameter; a module type introduced by a
    // with-constraint.
    assertIncludes(
      output,
      "optional argument x of function Opt_recalias.+g is always supplied"
    );
    assertIncludes(
      output,
      "optional argument x of function Opt_recalias_other.+g is never used"
    );
    assertIncludes(output, "Live Value +Included_sig.W2.X.+f");
    // module type of; a nested functor obtained through include.
    assertIncludes(output, "Live Value +Included_sig.W3.X.+f");
    assertIncludes(
      output,
      "optional argument x of function Opt_incl_f.+g is always supplied"
    );
    assertIncludes(
      output,
      "optional argument x of function Opt_cross_incl.+g is always supplied"
    );
    assertIncludes(
      output,
      "optional argument x of function Opt_rec_chain.+g is always supplied"
    );
    assertIncludes(
      output,
      "optional argument x of function Opt_y.+g is always supplied"
    );
    // A module type rooted at a functor application.
    assertIncludes(output, "Live Value +Shared_signature_arg.Used_mt.+f");
    assertIncludes(output, "Dead Value +Shared_signature_arg.Unused_mt.+f");
    // Module types rooted at a functor parameter: M.T, M.Sub.T2,
    // Outer (M).SM, through a parameter alias, and through include.
    assertIncludes(output, "Live Value +Shared_signature_arg.Apply_pt.Use_p.+f");
    assertIncludes(output, "Dead Value +Shared_signature_arg.Apply_pt.Unused_p.+f");
    assertIncludes(output, "Live Value +Shared_signature_arg.Apply_pt.Use_p2.+h");
    assertIncludes(output, "Live Value +Shared_signature_arg.Apply_app.Use_a.+f");
    assertIncludes(output, "Dead Value +Shared_signature_arg.Apply_app.Unused_a.+f");
    assertIncludes(
      output,
      "Live Value +Shared_signature_arg.Apply_pt2.Use_alias_mt.+f"
    );
    assertIncludes(
      output,
      "Live Value +Shared_signature_arg.Apply_pt2.Use_include_mt.+f"
    );
    // Module types through an aliased or applied member of an applied
    // functor's result.
    assertIncludes(output, "Live Value +Shared_signature_arg.Use_u.+f");
    assertIncludes(output, "Live Value +Shared_signature_arg.Use_u2.+k");
    // A forward alias of the parameter in a recursive group.
    assertIncludes(
      output,
      "optional argument x of function Opt_recfwd.+g is always supplied"
    );
    assertIncludes(
      output,
      "optional argument x of function Opt_recfwd_other.+g is never used"
    );
    // Sweep of parameter-alias forms: recursive alias of a parameter's
    // submodule, let-module alias chain, recursive alias of an outer alias,
    // alias passed as a functor argument. Each credited exactly once and
    // never leaked to an unrelated implementation.
    for (const m of ["Opt_sw1", "Opt_sw2", "Opt_sw3", "Opt_sw4"]) {
      assertIncludes(
        output,
        `optional argument x of function ${m}.+g is always supplied (1 calls)`
      );
    }
    assertIncludes(
      output,
      "optional argument x of function Opt_sw_other.+g is never used"
    );
    // Arguments constrained by a module type from outside the analysis root
    // (Set.OrderedType): inline and named.
    assertIncludes(output, "Live Value +Shared_signature_arg.Applied_ord.+compare");
    assertIncludes(output, "Live Value +Shared_signature_arg.Ord_named.+compare");
    // Module types inside an applied inline functor and inside a functor
    // parameter's type: their items are never declarations.
    assertIncludes(output, "Live Value +Shared_signature_arg.M_app.X.+f");
    assertIncludes(output, "Live Value +Shared_signature_arg.Arg_p.X.+f");
    // (Arg_p2.X.f is live: an argument's coerced items count as used.)
    assertNotIncludes(output, "Value +Shared_signature_arg.Applied_fp2.X.+f");
    assertNotIncludes(output, "Value +Shared_signature_arg.F_param.X.+f");
    // Constraint-wrapped right-hand sides: a recursive constrained partial
    // application, and a let-module constrained functor.
    assertIncludes(
      output,
      "optional argument x of function Opt_recc.+g is always supplied (1 calls)"
    );
    assertIncludes(
      output,
      "optional argument x of function Opt_letc.+g is always supplied (1 calls)"
    );
    // Partial applications: held by a let module, and bound in another file.
    assertIncludes(
      output,
      "optional argument x of function Opt_letpartial.+g is always supplied"
    );
    assertIncludes(
      output,
      "optional argument x of function Opt_cross_partial.+g is always supplied"
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
    // Generative functors: a unit application first, in the middle, last, in
    // a partial application, a recursive binding, a let module, and bound in
    // another file. An implementation never applied keeps its unused argument.
    for (const name of [
      "Opt_unit_first",
      "Opt_unit_mid",
      "Opt_unit_last",
      "Opt_unit_partial",
      "Opt_unit_end",
      "Opt_unit_rec",
      "Opt_unit_let",
      "Opt_cross_unit",
      "Opt_cross_unit2",
    ]) {
      assertIncludes(
        output,
        `optional argument x of function ${name}.+g is always supplied (1 calls)`
      );
    }
    assertIncludes(
      output,
      "optional argument x of function Opt_unit_none.+g is never used"
    );
    // Arguments that are themselves applications: directly, constrained,
    // curried, nested, generative, through an alias of the functor, with a
    // parameter as the inner argument, of an inline functor, bound in another
    // file, and a constrained inline structure. The calls are credited to the
    // applied functor's body only.
    for (const name of [
      "Mk_o",
      "Mk_o_c",
      "Mk_o2",
      "Mk_o_n",
      "Mk_o_unit",
      "Mk_o_a",
      "Mk_o_p",
      "Applied_app_inline",
      "Applied_struct",
    ]) {
      assertIncludes(
        output,
        `optional argument x of function ${name}.+g is always supplied (1 calls)`
      );
    }
    assertIncludes(
      output,
      "optional argument x of function Mk_cross.+g is always supplied (2 calls)"
    );
    assertIncludes(
      output,
      "optional argument x of function Mk_o_none.+g is never used"
    );
    // An applied functor re-exporting its argument: the argument's value is
    // used, another implementation of the module type stays dead.
    assertIncludes(output, "Live Value +Shared_signature_arg.Fwd_used.+f");
    assertIncludes(output, "Dead Value +Shared_signature_arg.Fwd_unused.+f");
    // Higher-order functors: a functor passed as an argument and applied in
    // the body, to a parameter, a fixed module, a submodule of a parameter,
    // through an alias of the functor parameter, in an include, partially
    // applied beforehand, through two levels; and first-class modules as
    // head and as argument, in the same file and from another file. Each
    // call is credited to the argument of the same application only.
    for (const name of [
      "Opt_ho",
      "Opt_fixed",
      "Opt_sub_holder.Sub",
      "Opt_alias_ho",
      "Opt_incl_ho",
      "Opt_partial_ho",
      "Opt_2",
      "Opt_fc",
      "Opt_fca",
      "Opt_cross_fc",
      "Opt_id",
    ]) {
      assertIncludes(
        output,
        `optional argument x of function ${name}.+g is always supplied (1 calls)`
      );
    }
    assertIncludes(
      output,
      "optional argument x of function Opt_twice.+g is always supplied (2 calls)"
    );
    // ... a functor whose body is directly the parameter's application, and a
    // higher-order functor from another file applied to a functor from a
    // third file.
    assertIncludes(
      output,
      "optional argument x of function Opt_direct_body.+g is always supplied (1 calls)"
    );
    assertIncludes(
      output,
      "optional argument x of function Opt_cross_ho.+g is always supplied (1 calls)"
    );
    // ... and with the functor parameter's type written inline: the passed
    // functor's values used through it stay live, its unused helper dead.
    assertIncludes(
      output,
      "optional argument x of function Opt_anon.+g is always supplied (1 calls)"
    );
    assertIncludes(output, "Live Value +Higher_order_more.Impl_anon.+run");
    assertIncludes(output, "Dead Value +Higher_order_more.Impl_anon.+helper");
    assertIncludes(
      output,
      "optional argument x of function Opt_none_ho.+g is never used"
    );
    // Inline functors returning (a submodule of) their parameter, or a
    // functor applied to it: the argument flows on; an unrelated
    // implementation stays dead.
    assertIncludes(output, "Live Value +Higher_order.Id_used.+f");
    assertIncludes(output, "Live Value +Higher_order.Id_sub_holder.Sub.+f");
    assertIncludes(output, "Live Value +Higher_order.Id_app.+f");
    assertIncludes(output, "Live Value +Higher_order.Id_curried.+f");
    assertIncludes(output, "Dead Value +Higher_order.Id_unused.+f");
    // A functor escaping as a first-class module passed to a function: its
    // calls are forwarded conservatively, never dropped.
    assertIncludes(
      output,
      "optional argument y of function P_esc.+h is always supplied"
    );
    assertNotIncludes(output, "P_esc.+h is never used");
    // ... including functors nested in a module that escapes, nested in
    // the result of an applied functor parameter, and a functor applied
    // directly whose packed value also flows through a function.
    assertIncludes(
      output,
      "optional argument z of function P2_esc.+k is always supplied"
    );
    assertNotIncludes(output, "P2_esc.+k is never used");
    assertIncludes(
      output,
      "optional argument cross of function Cross_esc.+k is always supplied"
    );
    assertNotIncludes(output, "Cross_esc.+k is never used");
    assertIncludes(
      output,
      "optional argument w of function P3_esc.+q is always supplied"
    );
    assertNotIncludes(output, "P3_esc.+q is never used");
    assertIncludes(
      output,
      "optional argument v of function P4_b.+u is always supplied"
    );
    assertNotIncludes(output, "P4_b.+u is never used");
    assertNotIncludes(output, "P4_a.+u is never used");
    // New enclosing applications discovered on later fixed-point rounds
    // still instantiate the original parameter-headed application.
    for (const name of ["Fixpoint_a", "Fixpoint_b"]) {
      assertIncludes(
        output,
        `optional argument y of function ${name}.+g is always supplied (1 calls)`
      );
    }
    // The two indirect applications share a source application ID but not
    // an enclosing context: C's omitted argument must not mix with B's call.
    assertIncludes(
      output,
      "optional argument y of function Fixpoint_c.+g is never used"
    );
    // A packed higher-order argument exported through an .mli resolves to
    // the implementation binding where its functor was registered.
    assertIncludes(
      output,
      "optional argument x of function Packed_arg.+g is always supplied (1 calls)"
    );
    // A foreign unpacked functor (and its alias) has no shape uid. Resolve
    // its packed binding precisely; an unpacked include escapes instead.
    assertIncludes(
      output,
      "optional argument x of function Unpacked_arg.+g is always supplied (1 calls)"
    );
    assertIncludes(
      output,
      "optional argument x of function Unpacked_unused.+g is never used"
    );
    assertIncludes(
      output,
      "optional argument included of function Unpacked_include_arg.+g is always supplied (1 calls)"
    );
    assertIncludes(
      output,
      "optional argument nested of function Unpacked_nested_arg.+g is always supplied (1 calls)"
    );
    for (const name of [
      "Direct.Open_arg", "Local.Local_open_arg", "Open_struct.Open_struct_arg",
      "Include_struct.Include_struct_arg", "Cross_unit.Cross_open_arg",
      "Mixed_open.Used_arg",
    ]) {
      assertIncludes(
        output,
        `optional argument opened of function ${name}.+g is always supplied (1 calls)`
      );
    }
    assertIncludes(
      output,
      "optional argument unrelated of function Unrelated.Unrelated_arg.+g is never used"
    );
    for (const name of [
      "Unused_import.Victim", "Unused_import.Called_victim", "Mixed_open.Victim",
    ]) {
      assertIncludes(
        output,
        `optional argument unused_open of function ${name}.+g is never used`
      );
    }
    for (const [name, argument] of [
      ["Local_alias_arg", "aliased"],
      ["Foreign_alias_arg", "foreign_alias"],
      ["Foreign_include_arg", "foreign_include"],
    ]) {
      assertIncludes(
        output,
        `optional argument ${argument} of function Aliases.${name}.+g is always supplied (1 calls)`
      );
    }
    for (const [name, argument] of [
      ["Repacked.Repacked_arg", "repacked"],
      ["Projected.Projected_arg", "projected"],
      ["Opaque_holder.Opaque_arg", "opaque"],
    ]) {
      assertIncludes(
        output,
        `optional argument ${argument} of function ${name}.+g is always supplied (1 calls)`
      );
    }
    for (const [name, argument] of [
      ["Repacked.Repacked_unused", "repacked"],
      ["Projected.Projected_unused", "projected"],
    ]) {
      assertIncludes(
        output,
        `optional argument ${argument} of function ${name}.+g is never used`
      );
    }
    assertIncludes(
      output,
      "optional argument untouched of function Opaque_holder.Opaque_unrelated.+h is never used"
    );
    for (const name of [
      "Partial_context.Partial_supplied_arg",
      "Partial_context.Passed_supplied_arg",
      "Partial_context.Packed_partial_arg",
      "Partial_context.Unit_partial_arg",
      "Partial_context.Forwarded_supplied_arg",
      "Foreign_supplied_arg",
    ]) {
      assertIncludes(
        output,
        `optional argument partial of function ${name}.+g is always supplied (1 calls)`
      );
    }
    for (const name of [
      "Partial_context.Partial_omitted_arg",
      "Partial_context.Passed_omitted_arg",
      "Partial_context.Forwarded_omitted_arg",
      "Foreign_omitted_arg",
    ]) {
      assertIncludes(
        output,
        `optional argument partial of function ${name}.+g is never used`
      );
    }
    // Escaping holders also expose functors defined outside their lexical
    // range through module aliases and includes.
    for (const [name, argument] of [
      ["Escaped_alias_arg", "alias"],
      ["Escaped_include_arg", "included"],
    ]) {
      assertIncludes(
        output,
        `optional argument ${argument} of function ${name}.+g is always supplied`
      );
      assertNotIncludes(output, `${name}.+g is never used`);
    }
    for (const name of ["Escaped_only", "Known_and_escaped"]) {
      assertIncludes(output, `Live Value +Escaped_coercion.${name}.Possible_arg.+needed`);
      assertNotIncludes(output, `Dead Value +Escaped_coercion.${name}.Possible_arg.+needed`);
      assertIncludes(output, `Dead Value +Escaped_coercion.${name}.Possible_arg.+unused`);
    }
    assertIncludes(
      output,
      "Dead Value +Escaped_coercion.Never_applied.Unrelated_arg.+needed"
    );
    assertIncludes(output, "Live Value +Escaped_coercion.Known_only.Known_arg.+needed");
    assertIncludes(output, "Dead Value +Escaped_coercion.Known_only.Unrelated_arg.+needed");
    assertIncludes(output, "Live Value +Escaped_coercion.Nested_stored.Possible_arg.N.+needed");
    assertIncludes(output, "Dead Value +Escaped_coercion.Nested_stored.Possible_arg.N.+unused");
    for (const name of ["Known_arg", "Anonymous_arg", "Included_arg"]) {
      assertIncludes(output, `optional argument mixed of function Mixed_holders.${name}.+g is always supplied (1 calls)`);
    }
    for (const name of ["Omitted_arg", "Unrelated_arg"]) {
      assertIncludes(output, `optional argument mixed of function Mixed_holders.${name}.+g is never used`);
    }
    assertIncludes(output, "Live Value +Review_round.Partial_result.F.+run");
    assertNotIncludes(output, "Dead Value +Review_round.Partial_result.F.+run");
    assertIncludes(output, "Dead Value +Review_round.Partial_result.F.+unused");
    assertIncludes(output, "optional argument result of function Partial_result.F.+run is always supplied (2 calls)");
    assertIncludes(output, "optional argument local_alias of function Local_alias.Arg.+g is always supplied (1 calls)");
    assertIncludes(output, "optional argument recursive_alias of function Recursive_alias.Arg.+g is always supplied (1 calls)");
    for (const name of ["Known.N", "B.N", "C.Actual", "D.N", "Packed_arg.N"]) {
      assertIncludes(output, `optional argument nested_arg of function ${name}.+g is always supplied (1 calls)`);
    }
    assertIncludes(output, "optional argument nested_arg of function Unrelated.N.+g is never used");
    assertIncludes(output, "optional argument foreign_nested of function Actual.N.+g is always supplied (1 calls)");
    assertIncludes(output, "optional argument foreign_nested of function Unrelated.N.+g is never used");
  }

  assertNotIncludes(output, "Parent is a dead module");
  assertNotIncludes(output, "Dead Value +Functor_argument.Ordered.+compare");
  assertNotIncludes(output, "Live Value +Functor_argument.Ordered.+unused");
  assertNotIncludes(output, "Dead Value +Functor_argument.Anonymous_set.+compare");
  assertNotIncludes(output, "Live Value +Functor_argument.Anonymous_set.+unused");
  assertNotIncludes(output, "Dead Value +Local_side_effects.+_info");
  assertNotIncludes(output, "Dead Value +Local_side_effects.+process");
  assertNotIncludes(output, "Dead Value +Local_side_effects.+register");

  // Two unwrapped libraries each define a `Dup_sig` compilation unit. The
  // functor result constraints in dup_a and dup_b must resolve to their own
  // Dup_sig, not to whichever one happens to be indexed first.
  console.log(`${cwd}: reanalyze duplicate compilation unit assertions`);
  const dupOutput = child_process.execFileSync(
    reanalyzeFile,
    ["-ci", "-debug", "-native-build-target", ".", "-dce-cmt", "_build/default"],
    {
      cwd,
      encoding: "utf8",
      maxBuffer: 256 * 1024 * 1024,
    }
  );

  assertIncludes(dupOutput, "Live Value +Dup_a_impl.Make.+f");
  assertIncludes(dupOutput, "Dead Value +Dup_a_impl.Make.+g");
  assertIncludes(dupOutput, "Dead Value +Dup_b_impl.Make.+f");
  assertIncludes(dupOutput, "Live Value +Dup_b_impl.Make.+g");
  assertIncludes(dupOutput, "Dead Value +Dup_b_impl.Make.+h");

  assertNotIncludes(dupOutput, "Dead Value +Dup_a_impl.Make.+f");
  assertNotIncludes(dupOutput, "Dead Value +Dup_b_impl.Make.+g");
  if (ocamlVersionAtLeast(5, 3)) {
    // The matching .cmti supplies the digest, while the sibling .cmt
    // supplies the shape needed to distinguish implementations of Dup_sig.S.
    assertIncludes(dupOutput, "Live Value +Dup_shape.A_chosen.+f");
    assertNotIncludes(dupOutput, "Live Value +Dup_shape.A_unused.+f");
    assertIncludes(dupOutput, "Dead Value +Dup_shape.A_unused.+f");
    assertIncludes(dupOutput, "Dead Value +Dup_shape.B_unused.+f");
  }
}

// A broad root may hold copies of the same compiled unit (a library's
// objects and its _build/install copy, byte and native objects). Scanning
// such a root must give exactly the single-directory result: copies are
// neither scanned twice nor mistaken for distinct units.
function runDuplicateLayoutTest() {
  const fs = require("fs");
  const os = require("os");
  const cwd = path.join(__dirname, "..", "examples", "regression");
  const cmtDir = path.join(
    cwd,
    "_build/default/src/.regression_fixture.objs/byte"
  );
  const root = fs.mkdtempSync(path.join(os.tmpdir(), "reanalyze-dup-"));
  for (const dir of ["a", "b", "c"]) fs.mkdirSync(path.join(root, dir));
  for (const file of fs.readdirSync(cmtDir)) {
    if (!/\.cmti?$/.test(file)) continue;
    // Dependencies duplicated in a and b, consumers in c.
    const dirs = /Shared_signature|Cross_/.test(file) ? ["a", "b"] : ["c"];
    for (const dir of dirs)
      fs.copyFileSync(path.join(cmtDir, file), path.join(root, dir, file));
  }
  const filter = (output) =>
    output
      .split("\n")
      .filter((line) => /never used|always supplied|dead module/.test(line))
      .sort()
      .join("\n");
  const run = (dir) =>
    child_process.execFileSync(
      reanalyzeFile,
      ["-ci", "-native-build-target", ".", "-dce-cmt", dir],
      { cwd, encoding: "utf8" }
    );
  console.log(`${cwd}: reanalyze duplicate-layout comparison`);
  const single = filter(run(cmtDir));
  const duplicated = filter(run(root));
  fs.rmSync(root, { recursive: true, force: true });
  if (single !== duplicated) {
    throw new Error(
      "Scanning a root with duplicated compiled units changed the result:\n" +
        duplicated
    );
  }
}

// Compile the same source as bytecode and native code, as Dune does: the
// native compilation reuses the bytecode .cmi and records no interface digest.
function runByteNativeDuplicateTest() {
  const fs = require("fs");
  const os = require("os");
  const cwd = fs.mkdtempSync(path.join(os.tmpdir(), "reanalyze-native-"));
  const source = path.join(
    __dirname,
    "..",
    "examples",
    "regression",
    "duplicate_native",
    "Duplicate_native.ml"
  );
  try {
    for (const dir of ["byte", "native"]) fs.mkdirSync(path.join(cwd, dir));
    child_process.execFileSync(
      "ocamlc",
      ["-bin-annot", "-c", "-o", "byte/Duplicate_native.cmo", source],
      { cwd }
    );
    child_process.execFileSync(
      "ocamlopt",
      [
        "-bin-annot", "-intf-suffix", ".ml", "-I", "byte", "-c",
        "-o", "native/Duplicate_native.cmx", source,
      ],
      { cwd }
    );
    const run = (root) =>
      child_process.execFileSync(
        reanalyzeFile,
        ["-ci", "-dce-cmt", root],
        { cwd, encoding: "utf8" }
      );
    console.log(`${cwd}: reanalyze byte/native duplicate comparison`);
    const single = run("byte");
    assertIncludes(
      single,
      "optional argument x of function +g is always supplied (1 calls)"
    );
    if (single !== run(".")) {
      throw new Error(
        "Scanning byte and native artifacts changed optional-call counts"
      );
    }
  } finally {
    fs.rmSync(cwd, { recursive: true, force: true });
  }
}

function runDuplicateContextTest() {
  if (!ocamlVersionAtLeast(5, 3)) return;
  const fs = require("fs");
  const os = require("os");
  const cwd = fs.mkdtempSync(path.join(os.tmpdir(), "reanalyze-context-"));
  const fixture = path.join(__dirname, "..", "examples", "regression", "duplicate_context");
  try {
    fs.copyFileSync(path.join(fixture, "Shared.ml"), path.join(cwd, "Shared.ml"));
    for (const dir of ["a", "b"]) {
      fs.mkdirSync(path.join(cwd, dir));
      fs.copyFileSync(path.join(fixture, dir, "Provider.ml"), path.join(cwd, dir, "Provider.ml"));
      child_process.execFileSync("ocamlc", [
        "-bin-annot", "-bin-annot-occurrences", "-c", `${dir}/Provider.ml`,
      ], { cwd });
      child_process.execFileSync("ocamlc", [
        "-bin-annot", "-bin-annot-occurrences", "-I", dir, "-c",
        "-o", `${dir}/Shared.cmo`, "Shared.ml",
      ], { cwd });
    }
    const run = () => child_process.execFileSync(
      reanalyzeFile, ["-ci", "-debug", "-dce-cmt", "."],
      { cwd, encoding: "utf8" }
    );
    const assertContexts = (output) => {
      if ((output.match(/Scanning .*Shared\.cmt /g) || []).length !== 2) {
        throw new Error("Both dependency contexts must be scanned exactly once");
      }
      if ((output.match(/Live Value \+Provider\.\+g:/g) || []).length !== 2) {
        throw new Error("Both dependency implementations must remain live");
      }
      if ((output.match(/optional argument x of function \+g is always supplied \(1 calls\)/g) || []).length !== 2) {
        throw new Error("Each dependency context must receive exactly one call");
      }
      assertNotIncludes(output, "Dead Value +Provider.+g");
    };
    console.log(`${cwd}: reanalyze identical source with distinct dependency contexts`);
    assertContexts(run());
    for (const dir of ["a", "b"]) {
      fs.mkdirSync(path.join(cwd, dir, "install"));
      for (const file of ["Provider.cmt", "Shared.cmt"]) {
        fs.copyFileSync(path.join(cwd, dir, file), path.join(cwd, dir, "install", file));
      }
    }
    assertContexts(run());
  } finally {
    fs.rmSync(cwd, { recursive: true, force: true });
  }
}

function runCompilationContextTests(sharedInterface = false) {
  if (!ocamlVersionAtLeast(5, 3)) return;
  const fs = require("fs");
  const cwd = fs.mkdtempSync(path.join(require("os").tmpdir(), "reanalyze-typing-context-"));
  const fixture = path.join(__dirname, "..", "examples", "regression", "compilation_context");
  const copy = (name) => fs.copyFileSync(path.join(fixture, name), path.join(cwd, name));
  const compile = (args, compiler = "ocamlc") => child_process.execFileSync(
    compiler, ["-bin-annot", "-bin-annot-occurrences", ...args], { cwd }
  );
  const run = (root, debug = false) => child_process.execFileSync(
    reanalyzeFile, ["-ci", ...(debug ? ["-debug"] : []), "-dce-cmt", root],
    { cwd, encoding: "utf8", timeout: 10000 }
  );
  try {
    for (const dir of ["a", "b", "native_layout/byte", "native_layout/native"]) {
      fs.mkdirSync(path.join(cwd, dir), { recursive: true });
    }
    copy("Shared.ml");
    copy("Relay.ml");
    const apiArgs = sharedInterface ? ["-I", "api"] : [];
    if (sharedInterface) {
      fs.mkdirSync(path.join(cwd, "api"));
      copy("Provider.mli");
      compile(["-c", "-o", "api/Provider.cmi", "Provider.mli"]);
    }
    for (const dir of ["a", "b"]) {
      for (const file of ["Provider.ml", `Use_${dir}.ml`]) copy(`${dir}/${file}`);
      compile([...(sharedInterface ? ["-intf-suffix", ".ml", ...apiArgs] : []), "-c", `${dir}/Provider.ml`]);
      for (const name of ["Shared", "Relay"]) {
        compile(["-I", dir, ...apiArgs, "-c", "-o", `${dir}/${name}.cmo`, `${name}.ml`]);
      }
      compile(["-I", dir, ...apiArgs, "-c", `${dir}/Use_${dir}.ml`]);
    }
    console.log(`${cwd}: reanalyze functor identity with ${sharedInterface ? "shared" : "distinct"} dependency interfaces`);
    const supplied = "optional argument context of function Arg.+g is always supplied (1 calls)";
    const omitted = "optional argument context of function Arg.+g is never used";
    assertIncludes(run("a"), supplied);
    assertIncludes(run("b"), omitted);
    const assertContexts = (output) => {
      assertIncludes(output, supplied);
      assertIncludes(output, omitted);
      for (const name of ["Partial_arg", "Packed_arg", "Relayed_arg"]) {
        assertIncludes(output, `optional argument context of function ${name}.+g is always supplied (1 calls)`);
        assertIncludes(output, `optional argument context of function ${name}.+g is never used`);
      }
      if ((output.match(/Scanning .*Shared\.cmt /g) || []).length !== 2) {
        throw new Error("Both Shared functor contexts must be scanned exactly once");
      }
    };
    assertContexts(run(".", true));

    for (const name of ["First", "Second", "Opened"]) copy(`${name}.ml`);
    compile(["-c", "First.ml"]);
    compile(["-c", "Second.ml"]);
    compile(["-open", "First", "-open", "Second", "-c", "-o", "a/Opened.cmo", "Opened.ml"]);
    compile(["-open", "Second", "-open", "First", "-c", "-o", "b/Opened.cmo", "Opened.ml"]);
    const assertOpens = (output) => {
      for (const name of ["First", "Second"]) {
        assertIncludes(output, `Live Value +${name}.+g`);
        assertNotIncludes(output, `Dead Value +${name}.+g`);
      }
      if ((output.match(/Scanning .*Opened\.cmt /g) || []).length !== 2 ||
          (output.match(/optional argument opened of function \+g is always supplied \(1 calls\)/g) || []).length !== 2) {
        throw new Error("Ordered -open contexts must each contribute one call");
      }
    };
    console.log(`${cwd}: reanalyze ordered implicit opens`);
    assertOpens(run(".", true));
    for (const dir of ["a", "b"]) {
      fs.mkdirSync(path.join(cwd, dir, "install"));
      for (const file of fs.readdirSync(path.join(cwd, dir)).filter((f) => f.endsWith(".cmt"))) {
        fs.copyFileSync(path.join(cwd, dir, file), path.join(cwd, dir, "install", file));
      }
    }
    const copies = run(".", true);
    assertContexts(copies);
    assertOpens(copies);

    for (const name of ["Native_provider", "Native_use"]) {
      copy(`${name}.ml`);
      compile(["-I", "native_layout/byte", "-c", "-o", `native_layout/byte/${name}.cmo`, `${name}.ml`]);
    }
    for (const name of ["Native_provider", "Native_use"]) {
      compile(["-intf-suffix", ".ml", "-I", "native_layout/byte", "-I", "native_layout/native",
        "-c", "-o", `native_layout/native/${name}.cmx`, `${name}.ml`], "ocamlopt");
    }
    console.log(`${cwd}: reanalyze native-only cross-unit functor imports`);
    const byte = run("native_layout/byte");
    assertIncludes(byte, "optional argument native of function Arg.+g is always supplied (1 calls)");
    for (const root of ["native_layout/native", "native_layout"]) {
      if (run(root) !== byte) throw new Error(`Cross-unit attribution changed for ${root}`);
    }
    for (const name of ["Safe_alias", "Nested_alias"]) {
      copy(`${name}.ml`);
      compile(["-o", `${name}.exe`, `${name}.ml`]);
      child_process.execFileSync(path.join(cwd, `${name}.exe`), [], { cwd, timeout: 10000 });
      console.log(`${cwd}: bounded analysis of ${name}`);
      assertIncludes(run(`${name}.cmt`), "Analysis reported 0 issues");
    }
  } finally {
    fs.rmSync(cwd, { recursive: true, force: true });
  }
}

function runFunctorScanOrderTest(providerName, consumerName, assertions) {
  if (!ocamlVersionAtLeast(5, 3)) return;
  const fs = require("fs");
  const os = require("os");
  const cwd = path.join(__dirname, "..", "examples", "regression");
  const cmtDir = path.join(cwd, "_build/default/src/.regression_fixture.objs/byte");
  const root = fs.mkdtempSync(path.join(os.tmpdir(), "reanalyze-unpack-order-"));
  try {
    for (const dir of ["first", "second"]) fs.mkdirSync(path.join(root, dir));
    const files = fs.readdirSync(cmtDir).filter((file) => /\.cmti?$/.test(file));
    const provider = `regression_fixture__${providerName}.cmt`;
    const consumer = `regression_fixture__${consumerName}.cmt`;
    const orders = [];
    console.log(`${cwd}: reanalyze ${providerName} in both scan orders`);
    for (const providerDir of ["first", "second"]) {
      const otherDir = providerDir === "first" ? "second" : "first";
      for (const file of files) {
        const dir = file === provider ? providerDir : otherDir;
        fs.copyFileSync(path.join(cmtDir, file), path.join(root, dir, file));
      }
      const output = child_process.execFileSync(
        reanalyzeFile,
        ["-ci", "-debug", "-native-build-target", ".", "-dce-cmt", root],
        { cwd, encoding: "utf8", maxBuffer: 256 * 1024 * 1024 }
      );
      assertIncludes(output, `Scanning ${provider} `);
      assertIncludes(output, `Scanning ${consumer} `);
      orders.push(
        output.indexOf(`Scanning ${provider} `) <
          output.indexOf(`Scanning ${consumer} `)
      );
      for (const assertion of assertions) assertIncludes(output, assertion);
      for (const file of files) {
        const dir = file === provider ? providerDir : otherDir;
        fs.unlinkSync(path.join(root, dir, file));
      }
    }
    if (orders[0] === orders[1]) {
      throw new Error("Scan-order test did not reverse the unit order");
    }
  } finally {
    fs.rmSync(root, { recursive: true, force: true });
  }
}

// The importer was compiled against digest_a. A mismatching Collision unit
// beside it must not hide that dependency or replace it when it is absent.
function runImportDigestSelectionTest() {
  if (!ocamlVersionAtLeast(5, 3)) return;
  const fs = require("fs");
  const os = require("os");
  const cwd = path.join(__dirname, "..", "examples", "regression");
  const temp = fs.mkdtempSync(path.join(os.tmpdir(), "reanalyze-digest-"));
  const root = path.join(temp, "layout");
  try {
    for (const dir of ["provider", "consumer"]) {
      fs.mkdirSync(path.join(root, dir), { recursive: true });
    }
    const copy = (library, unit, dir) =>
      fs.copyFileSync(
        path.join(cwd, "_build/default", library, `.${library}.objs/byte`, unit),
        path.join(root, dir, unit)
      );
    copy("digest_a", "collision.cmt", "provider");
    copy("digest_b", "collision.cmt", "consumer");
    copy("digest_use", "use_collision.cmt", "consumer");
    const run = () =>
      child_process.execFileSync(
        reanalyzeFile,
        ["-ci", "-debug", "-native-build-target", ".", "-dce-cmt", root],
        { cwd, encoding: "utf8", maxBuffer: 256 * 1024 * 1024 }
      );
    console.log(`${cwd}: reanalyze import digest before sibling preference`);
    const present = run();
    assertIncludes(present, "Live Value +Collision.Chosen_impl.+g");
    assertIncludes(present, "Dead Value +Collision.Unrelated_impl.+g");
    assertIncludes(
      present,
      "optional argument x of function Chosen_impl.+g is always supplied (1 calls)"
    );
    assertNotIncludes(present, "Live Value +Collision.Unrelated_impl.+g");

    fs.renameSync(
      path.join(root, "provider/collision.cmt"),
      path.join(temp, "collision.cmt")
    );
    console.log(`${cwd}: reanalyze missing imported digest stays unresolved`);
    const absent = run();
    assertIncludes(absent, "Dead Value +Collision.Unrelated_impl.+g");
    assertNotIncludes(absent, "Live Value +Collision.Unrelated_impl.+g");
    assertNotIncludes(absent, "function Unrelated_impl.+g is always supplied");
  } finally {
    fs.rmSync(temp, { recursive: true, force: true });
  }
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
    runDuplicateLayoutTest();
    runByteNativeDuplicateTest();
    runDuplicateContextTest();
    runCompilationContextTests();
    runCompilationContextTests(true);
    runFunctorScanOrderTest("Nested_arguments_packed", "Nested_arguments", [
      "optional argument foreign_nested of function Actual.N.+g is always supplied (1 calls)",
      "optional argument foreign_nested of function Unrelated.N.+g is never used",
    ]);
    runFunctorScanOrderTest("Unpacked_functor", "Unpacked_functor_use", [
      "optional argument x of function Unpacked_arg.+g is always supplied (1 calls)",
      "optional argument x of function Unpacked_unused.+g is never used",
      "optional argument nested of function Unpacked_nested_arg.+g is always supplied (1 calls)",
    ]);
    runFunctorScanOrderTest("Attribution_sweep", "Partial_context_use", [
      "optional argument partial of function Foreign_supplied_arg.+g is always supplied (1 calls)",
      "optional argument partial of function Foreign_omitted_arg.+g is never used",
    ]);
    runFunctorScanOrderTest("Unpacked_unused", "Unpacked_open", [
      "optional argument unused_open of function Unused_import.Victim.+g is never used",
      "optional argument unused_open of function Unused_import.Called_victim.+g is never used",
      "optional argument unused_open of function Mixed_open.Victim.+g is never used",
      "optional argument foreign_alias of function Aliases.Foreign_alias_arg.+g is always supplied (1 calls)",
      "optional argument foreign_include of function Aliases.Foreign_include_arg.+g is always supplied (1 calls)",
    ]);
    runImportDigestSelectionTest();
    checkDiff();

    console.log("Test successful!");
  } catch (e) {
    console.error(`Test failed unexpectedly: ${e.message}`);
    console.error(e);
    process.exit(1);
  }
}

main();
