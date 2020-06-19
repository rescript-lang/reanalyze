let processCallee = (~def, ~loc, callee) =>
  switch (callee) {
  | Path.Pident(id) =>
    let id = Ident.name(id);
    switch (Il.findDef(~id)) {
    | Some(defCallee) => def |> Il.Def.emit(~instr=Il.Call(defCallee.id))
    | None =>
      Log_.info(~count=false, ~loc, ~name="Noalloc", (ppf, ()) =>
        Format.fprintf(ppf, "Callee not recognized: %s", id)
      );
      assert(false);
    };
  | _ =>
    switch (callee |> Path.name) {
    | "Pervasives.+"
    | "Stdlib.+" => def |> Il.Def.emit(~instr=Il.I32Add)
    | "Pervasives.+."
    | "Stdlib.+." => def |> Il.Def.emit(~instr=Il.F64Add)
    | "Pervasives.*."
    | "Stdlib.*." => def |> Il.Def.emit(~instr=Il.F64Mul)

    | name =>
      Log_.info(~count=false, ~loc, ~name="Noalloc", (ppf, ()) =>
        Format.fprintf(ppf, "Callee not recognized: %s", name)
      );
      assert(false);
    }
  };

type instKind =
  | Param
  | Decl
  | Set;

let rec processTyp = (~def: Il.Def.t, ~loc, typ: Types.type_expr) =>
  switch (typ.desc) {
  | Ttuple(ts) =>
    let scopes = ts |> List.map(processTyp(~def, ~loc));
    Il.Env.Tuple(scopes);
  | Tlink(t)
  | Tsubst(t) => t |> processTyp(~def, ~loc)
  | Tconstr(_)
  | Tvar(_) =>
    let offset = def.nextOffset;
    def.nextOffset = offset + 1;
    Il.Env.Local(offset);

  | _ =>
    Log_.info(~count=false, ~loc, ~name="Noalloc", (ppf, ()) =>
      Format.fprintf(ppf, "Type not supported")
    );
    assert(false);
  };

let rec processScope =
        (~def: Il.Def.t, ~forward, ~instrKind, ~scope: Il.Env.scope) => {
  switch (scope) {
  | Tuple(scopes) =>
    (forward ? scopes : List.rev(scopes))
    |> List.iter(s => {processScope(~def, ~forward, ~instrKind, ~scope=s)})
  | Local(offset) =>
    let instr =
      switch (instrKind) {
      | Param => Il.Param(offset)
      | Decl => Il.LocalDecl(offset)
      | Set => Il.LocalSet(offset)
      };
    def |> Il.Def.emit(~instr);
  };
};

let rec processFunPat = (~def, ~env, pat: Typedtree.pattern) =>
  switch (pat.pat_desc) {
  | Tpat_var(id, _)
  | Tpat_alias({pat_desc: Tpat_any}, id, _) =>
    let scope = pat.pat_type |> processTyp(~def, ~loc=pat.pat_loc);
    processScope(~def, ~forward=true, ~instrKind=Param, ~scope);
    let newEnv =
      env |> Il.Env.addFunctionParameter(~id=id |> Ident.name, ~scope);
    (newEnv, scope);

  | Tpat_tuple(pats) =>
    let (newEnv, scopes) =
      pats
      |> List.fold_left(
           ((e, scopes), p) => {
             let (newEnv, scope) = p |> processFunPat(~def, ~env=e);
             (newEnv, [scope, ...scopes]);
           },
           (env, []),
         );
    (newEnv, Il.Env.Tuple(scopes));

  | _ =>
    Log_.info(~count=false, ~loc=pat.pat_loc, ~name="Noalloc", (ppf, ()) =>
      Format.fprintf(ppf, "Argument pattern not supported")
    );
    assert(false);
  };

let rec processFunDef = (~def, ~env, ~params, expr: Typedtree.expression) =>
  switch (expr.exp_desc) {
  | Texp_function({
      arg_label: Nolabel,
      param,
      cases: [{c_lhs, c_guard: None, c_rhs}],
      partial: Total,
    }) =>
    let (newEnv, typ) = c_lhs |> processFunPat(~def, ~env);
    c_rhs
    |> processFunDef(~def, ~env=newEnv, ~params=[(param, typ), ...params]);

  | _ => (env, expr, params)
  };

let processConst = (~def, ~loc, const: Asttypes.constant) =>
  switch (const) {
  | Const_int(n) =>
    def |> Il.Def.emit(~instr=Il.Const(Il.I32(n |> Int32.of_int)))
  | Const_float(s) =>
    let sWithDecimal = s.[String.length(s) - 1] == '.' ? s ++ "0" : s;
    def |> Il.Def.emit(~instr=Il.Const(Il.F64(sWithDecimal)));
  | _ =>
    Log_.info(~count=false, ~loc, ~name="Noalloc", (ppf, ()) =>
      Format.fprintf(ppf, "Constant not supported")
    );
    assert(false);
  };

let rec processLocalBinding =
        (~env, ~pat: Typedtree.pattern, ~scope: Il.Env.scope) =>
  switch (pat.pat_desc, scope) {
  | (Tpat_var(id, _), _) =>
    env |> Il.Env.addFunctionParameter(~id=id |> Ident.name, ~scope)

  | (Tpat_tuple(pats), Tuple(scopes)) =>
    let patsAndScopes = List.combine(pats, scopes);
    patsAndScopes
    |> List.fold_left(
         (e, (p, s)) => processLocalBinding(~env=e, ~pat=p, ~scope=s),
         env,
       );
  | _ => assert(false)
  }

and processExpr = (~def, ~env, expr: Typedtree.expression) =>
  switch (expr.exp_desc) {
  | Texp_constant(const) => const |> processConst(~def, ~loc=expr.exp_loc)

  | Texp_ident(id, _, _) =>
    let id = Path.name(id);
    let rec emitScope = (scope: Il.Env.scope) =>
      switch (scope) {
      | Local(offset) => def |> Il.Def.emit(~instr=Il.LocalGet(offset))
      | Tuple(scopes) => scopes |> List.iter(emitScope)
      };
    switch (env |> Il.Env.find(~id)) {
    | Some(scope) => emitScope(scope)

    | None =>
      Log_.info(~count=false, ~loc=expr.exp_loc, ~name="Noalloc", (ppf, ()) =>
        Format.fprintf(ppf, "Id not found: %s", id)
      );

      assert(false);
    };

  | Texp_apply(
      {exp_desc: Texp_ident(callee, _, vd), exp_loc: callee_loc},
      args,
    ) =>
    let kind = vd.val_type |> Il.Kind.fromType;
    args
    |> List.iteri((i, (argLabel: Asttypes.arg_label, argOpt)) =>
         switch (argLabel, argOpt) {
         | (Nolabel, Some((arg: Typedtree.expression))) =>
           switch (kind) {
           | Arrow(declKinds, _) =>
             let declKind = declKinds[i];
             let argKind = arg.exp_type |> Il.Kind.fromType;
             if (argKind != declKind) {
               Log_.info(
                 ~count=true, ~loc=arg.exp_loc, ~name="Noalloc", (ppf, ()) =>
                 Format.fprintf(
                   ppf,
                   "Function call to @{<info>%s@}: parameter %d has kind @{<info>%s@} but the supplied argument has kind @{<info>%s@}",
                   callee |> Path.name,
                   i,
                   declKind |> Il.Kind.toString,
                   argKind |> Il.Kind.toString,
                 )
               );
             };
           | _ => assert(false)
           };
           arg |> processExpr(~def, ~env);
         | _ =>
           Log_.info(
             ~count=false, ~loc=expr.exp_loc, ~name="Noalloc", (ppf, ()) =>
             Format.fprintf(ppf, "Argument not supported")
           )
         }
       );
    callee |> processCallee(~def, ~loc=callee_loc);

  | Texp_function(_) =>
    let (env, body, params) = expr |> processFunDef(~def, ~env, ~params=[]);
    if (params == []) {
      Log_.info(~count=false, ~loc=expr.exp_loc, ~name="Noalloc", (ppf, ()) =>
        Format.fprintf(ppf, "Cannot decode function parameters")
      );
      assert(false);
    };
    def.params = params;
    body |> processExpr(~def, ~env);

  | Texp_tuple(l) => l |> List.iter(processExpr(~def, ~env))

  | Texp_let(Nonrecursive, [vb], inExpr) =>
    let scope =
      vb.vb_expr.exp_type |> processTyp(~def, ~loc=vb.vb_expr.exp_loc);
    processScope(~def, ~forward=true, ~instrKind=Decl, ~scope);
    vb.vb_expr |> processExpr(~def, ~env);
    processScope(~def, ~forward=false, ~instrKind=Set, ~scope);
    let newEnv = processLocalBinding(~env, ~pat=vb.vb_pat, ~scope);
    inExpr |> processExpr(~def, ~env=newEnv);

  | _ =>
    Log_.info(~count=false, ~loc=expr.exp_loc, ~name="Noalloc", (ppf, ()) =>
      Format.fprintf(ppf, "Expression not supported")
    );
    assert(false);
  };

let processValueBinding = (~id, ~loc, ~expr: Typedtree.expression) => {
  Log_.item("no-alloc binding for %s@.", id |> Ident.name);
  let kind = Il.Kind.fromType(expr.exp_type);
  let def = Il.createDef(~id, ~loc, ~kind);
  let env = Il.Env.create();

  expr |> processExpr(~def, ~env);
};

let collectValueBinding = (super, self, vb: Typedtree.value_binding) => {
  switch (vb.vb_pat.pat_desc) {
  | Tpat_var(id, _)
      when vb.vb_attributes |> Annotation.hasAttribute((==)("noalloc")) =>
    processValueBinding(~loc=vb.vb_loc, ~id, ~expr=vb.Typedtree.vb_expr)
  | _ => ()
  };
  let r = super.Tast_mapper.value_binding(self, vb);
  r;
};

let traverseStructure = {
  /* Tast_mapper */
  let super = Tast_mapper.default;

  let value_binding = (self, vb) => vb |> collectValueBinding(super, self);
  Tast_mapper.{...super, value_binding};
};

let processCmt = (cmt_infos: Cmt_format.cmt_infos) =>
  switch (cmt_infos.cmt_annots) {
  | Interface(_) => ()
  | Implementation(structure) =>
    structure |> traverseStructure.structure(traverseStructure) |> ignore
  | _ => ()
  };

let reportResults = (~ppf) => Il.dumpDefs(~ppf);