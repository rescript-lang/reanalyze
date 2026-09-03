(* Adapted from https://github.com/LexiFi/dead_code_analyzer *)

open DeadCommon

let checkAnyValueBindingWithNoSideEffects
    ({vb_pat = {pat_desc}; vb_expr = expr; vb_loc = loc} :
      Typedtree.value_binding) =
  match pat_desc with
  | Tpat_any when (not (SideEffects.checkExpr expr)) && not loc.loc_ghost ->
    let name = "_" |> Name.create ~isInterface:false in
    let currentModulePath = ModulePath.getCurrent () in
    let path = currentModulePath.path @ [!Common.currentModuleName] in
    name
    |> addValueDeclaration ~path ~loc ~moduleLoc:currentModulePath.loc
         ~sideEffects:false
  | _ -> ()

let collectValueBinding super self (vb : Typedtree.value_binding) =
  let oldCurrentBindings = !Current.bindings in
  let oldLastBinding = !Current.lastBinding in
  checkAnyValueBindingWithNoSideEffects vb;
  let loc =
    match vb.vb_pat.pat_desc with
    #if OCAML_VERSION < (5, 2, 0)
    | Tpat_var (id, {loc = {loc_start; loc_ghost} as loc})
    | Tpat_alias
        ({pat_desc = Tpat_any}, id, {loc = {loc_start; loc_ghost} as loc})
    #else
    | Tpat_var (id, {loc = {loc_start; loc_ghost} as loc}, _)
    #if OCAML_VERSION >= (5, 4, 0)
    | Tpat_alias
        ({pat_desc = Tpat_any}, id, {loc = {loc_start; loc_ghost} as loc}, _, _)
    #else
    | Tpat_alias
        ({pat_desc = Tpat_any}, id, {loc = {loc_start; loc_ghost} as loc}, _)
    #endif
    #endif
      when (not loc_ghost) && not vb.vb_loc.loc_ghost ->
      let name = Ident.name id |> Name.create ~isInterface:false in
      let optionalArgs =
        vb.vb_expr.exp_type |> DeadOptionalArgs.fromTypeExpr
        |> OptionalArgs.fromList
      in
      let exists =
        match PosHash.find_opt decls loc_start with
        | Some {declKind = Value r} ->
          r.optionalArgs <- optionalArgs;
          true
        | _ -> false
      in
      let currentModulePath = ModulePath.getCurrent () in
      let path = currentModulePath.path @ [!Common.currentModuleName] in
      let isFirstClassModule =
        match Compat.get_desc vb.vb_expr.exp_type with
        | Tpackage _ -> true
        | _ -> false
      in
      let isToplevel = oldLastBinding = Location.none in
      let sideEffects = SideEffects.checkExpr vb.vb_expr in
      (if (not exists) && not isFirstClassModule then
       name
       |> addValueDeclaration ~isToplevel ~loc ~moduleLoc:currentModulePath.loc
            ~optionalArgs ~path ~sideEffects);
      (* Keep side-effectful local lets reachable from the enclosing binding,
         even when the local name itself is not read. *)
      (if (not isToplevel) && sideEffects then
       addValueReference ~addFileReference:false ~locFrom:oldLastBinding
         ~locTo:loc);
      (match PosHash.find_opt decls loc_start with
      | None -> ()
      | Some decl ->
        (* Value bindings contain the correct location for the entire declaration: update final position.
           The previous value was taken from the signature, which only has positions for the id. *)
        let declKind =
          match decl.declKind with
          | Value vk ->
            DeclKind.Value
              {vk with sideEffects = SideEffects.checkExpr vb.vb_expr}
          | dk -> dk
        in
        PosHash.replace decls loc_start
          {
            decl with
            declKind;
            posEnd = vb.vb_loc.loc_end;
            posStart = vb.vb_loc.loc_start;
          });
      loc
    | _ -> !Current.lastBinding
  in
  Current.bindings := PosSet.add loc.loc_start !Current.bindings;
  Current.lastBinding := loc;
  let r = super.Tast_mapper.value_binding self vb in
  Current.bindings := oldCurrentBindings;
  Current.lastBinding := oldLastBinding;
  r

type functorParameter = {
  paramId : Ident.t;
  functorDef : Lexing.position;
      (** position of the name of the module binding defining the functor *)
  paramIndex : int;  (** position of the parameter, for curried functors *)
}

let functorParameters : functorParameter list ref = ref []

(* Name position of the module binding being traversed, see [Tstr_module]. *)
let currentModuleBindingPos = ref Lexing.dummy_pos

let findFunctorParameter (path : Path.t) =
  match Path.head path with
  | head -> List.find_opt (fun p -> Ident.same p.paramId head) !functorParameters
  | exception _ -> None

let isFunctorParameterPath path = findFunctorParameter path <> None

(* Calls with optional arguments made through a functor parameter, keyed by
   the functor definition, parameter index, and path of the value within the
   parameter (e.g. ["g"] for [M.g], ["Sub"; "g"] for [M.Sub.g]). They are
   credited to the actual arguments at application sites, once all files are
   scanned. *)
let parameterCalls :
    (Lexing.position * int * string list, (string list * string list) list)
    Hashtbl.t =
  Hashtbl.create 16

type delayedApplication = {
  appliedFunctor : Lexing.position;
  argIndex : int;
  resolveItem : string list -> Location.t option;
      (** implementation of a value of the actual argument, by path *)
}

let delayedApplications : delayedApplication list ref = ref []

let rec pathComponents (path : Path.t) =
  match path with
  | Pident _ -> Some []
  | Pdot (p, name) -> (
    match pathComponents p with
    | Some comps -> Some (comps @ [name])
    | None -> None)
  | _ -> None

let processOptionalArgs ~expType ~(locFrom : Location.t) ~locTo ?locToImpl
    ~path args =
  let args =
    List.map (fun (lbl, arg) -> (lbl, Compat.applyArgToOption arg)) args
  in
  if expType |> DeadOptionalArgs.hasOptionalArgs then (
    let supplied = ref [] in
    let suppliedMaybe = ref [] in
    args
    |> List.iter (fun (lbl, arg) ->
           let argIsSupplied =
             match arg with
             | Some
                 {
                   Typedtree.exp_desc =
                     Texp_construct (_, {cstr_name = "Some"}, _);
                 } ->
               Some true
             | Some
                 {
                   Typedtree.exp_desc =
                     Texp_construct (_, {cstr_name = "None"}, _);
                 } ->
               Some false
             | Some _ -> None
             | None -> Some false
           in
           match lbl with
           | Asttypes.Optional s when not locFrom.loc_ghost ->
             if argIsSupplied <> Some false then supplied := s :: !supplied;
             if argIsSupplied = None then suppliedMaybe := s :: !suppliedMaybe
           | _ -> ());
    let call = (!supplied, !suppliedMaybe) in
    let parameter = findFunctorParameter path in
    (match (parameter, pathComponents path) with
    | Some {functorDef; paramIndex}, Some components ->
      let key = (functorDef, paramIndex, components) in
      let calls =
        match Hashtbl.find_opt parameterCalls key with
        | Some calls -> calls
        | None -> []
      in
      Hashtbl.replace parameterCalls key (call :: calls)
    | _ -> ());
    call
    |> DeadOptionalArgs.addReferences ~locFrom ~locTo ?locToImpl
         ~forwardable:(parameter = None) ~path)

(* Implementation locations of identifier occurrences resolved through
   shapes. See [Compat.resolveIdentOccurrences]. *)
let identResolutions = ref Compat.emptyIdentResolutions

(* References whose target may be redirected to a shape-resolved
   implementation. Decided in [forceDelayedItems], once every declaration is
   known: if the original target is a declaration (e.g. a [val] in an .mli), it
   is kept, otherwise the implementation is referenced. *)
type redirectedReference = {
  locFrom : Location.t;
  locTo : Location.t;
  locToImpl : Location.t;
}

let delayedRedirects : redirectedReference list ref = ref []

let findResolution ~(identLoc : Location.t) ~(path : Path.t) =
  !identResolutions.valueImpl identLoc (Path.last path)

(* Functor parameters in scope during traversal. A reference through a
   parameter (e.g. [M.f] in [functor (M : S) -> ...]) is credited to the actual
   arguments at application sites, via the coercion in [Tmod_apply]; it must
   not be forwarded to every implementation of the module type item. *)
(* (module type item position, referencing position) pairs that must not be
   forwarded to implementations. *)
module PosPairSet = Set.Make (struct
  type t = Lexing.position * Lexing.position

  let compare = compare
end)

let nonForwardableReferences = ref PosPairSet.empty

let effectiveLocFrom (locFrom : Location.t) =
  let lastBinding = !Current.lastBinding in
  match lastBinding = Location.none with
  | true -> locFrom
  | false -> lastBinding

let addRedirect ~(locFrom : Location.t) ~(locTo : Location.t) ~locToImpl =
  match locToImpl with
  | Some (locToImpl : Location.t) when locToImpl.loc_start <> locTo.loc_start ->
    let locFrom = effectiveLocFrom locFrom in
    if not locFrom.loc_ghost then
      delayedRedirects := {locFrom; locTo; locToImpl} :: !delayedRedirects
  | _ -> addValueReference ~addFileReference:true ~locFrom ~locTo

let addValueReferenceOrRedirect ~(locFrom : Location.t) ~(locTo : Location.t)
    ~path =
  let pair = (locTo.loc_start, (effectiveLocFrom locFrom).loc_start) in
  let locToImpl = findResolution ~identLoc:locFrom ~path in
  (if isFunctorParameterPath path then
     nonForwardableReferences := PosPairSet.add pair !nonForwardableReferences
   else if locToImpl = None && PosPairSet.mem pair !nonForwardableReferences
   then
     (* A non-parameter reference from the same position that stays targeted
        at the module type item keeps the pair forwardable. A redirected one
        does not: it never lands on the item. *)
     nonForwardableReferences := PosPairSet.remove pair !nonForwardableReferences);
  addRedirect ~locFrom ~locTo ~locToImpl

let rec collectExpr super self (e : Typedtree.expression) =
  let locFrom = e.exp_loc in
  (match e.exp_desc with
  | Texp_ident (_path, _, {Types.val_loc = {loc_ghost = false; _} as locTo})
    ->
    (* if Path.name _path = "rc" then assert false; *)
    if locFrom = locTo && _path |> Path.name = "emptyArray" then (
      (* Work around lowercase jsx with no children producing an artifact `emptyArray`
         which is called from its own location as many things are generated on the same location. *)
      if !Common.Cli.debug then
        Log_.item "addDummyReference %s --> %s@."
          (Location.none.loc_start |> posToString)
          (locTo.loc_start |> posToString);
      ValueReferences.add locTo.loc_start Location.none.loc_start)
    else addValueReferenceOrRedirect ~locFrom ~locTo ~path:_path
  | Texp_apply
      ( {
          exp_desc =
            Texp_ident
              (path, _, {Types.val_loc = {loc_ghost = false; _} as locTo});
          exp_type;
          exp_loc = identLoc;
        },
        args ) ->
    let locToImpl = findResolution ~identLoc ~path in
    args
    |> processOptionalArgs ~expType:exp_type
         ~locFrom:(locFrom : Location.t)
         ~locTo ?locToImpl ~path
  | Texp_let
      ( (* generated for functions with optional args *)
      Nonrecursive,
        [
          {
            #if OCAML_VERSION < (5, 2, 0)
            vb_pat = {pat_desc = Tpat_var (idArg, _)};
            #else
            vb_pat = {pat_desc = Tpat_var (idArg, _, _)};
            #endif
            vb_expr =
              {
                exp_desc =
                  Texp_ident
                    ( path,
                      _,
                      {Types.val_loc = {loc_ghost = false; _} as locTo} );
                exp_type;
              };
          };
        ],
        {
          exp_desc =
            #if OCAML_VERSION < (5, 2, 0)
            Texp_function
              {
                cases =
                  [
                    {
                      c_lhs = {pat_desc = Tpat_var (etaArg, _)};
                      c_rhs =
                        {
                          exp_desc =
                            Texp_apply
                              ({exp_desc = Texp_ident (idArg2, _, _)}, args);
                        };
                    };
                  ];
              };
            #else
              Texp_function(_,
              Tfunction_cases {
                cases =
                  [
                    {
                      c_lhs = {pat_desc = Tpat_var (etaArg, _, _)};
                      c_rhs =
                        {
                          exp_desc =
                            Texp_apply
                              ({exp_desc = Texp_ident (idArg2, _, _)}, args);
                        };
                    };
                  ];
              });
            #endif
        } )
    when Ident.name idArg = "arg"
         && Ident.name etaArg = "eta"
         && Path.name idArg2 = "arg" ->
    args
    |> processOptionalArgs ~expType:exp_type
         ~locFrom:(locFrom : Location.t)
         ~locTo ~path
  | Texp_field
      (_, _, {lbl_loc = {Location.loc_start = posTo; loc_ghost = false}; _})
    ->
    if !Config.analyzeTypes then
      DeadType.addTypeReference ~posTo ~posFrom:locFrom.loc_start
  | Texp_construct
      ( _,
        {
          cstr_loc = {Location.loc_start = posTo; loc_ghost} as locTo;
          cstr_tag;
        },
        _ ) ->
    (match cstr_tag with
    | Cstr_extension (path, _) ->
      path |> DeadException.markAsUsed ~locFrom ~locTo
    | _ -> ());
    if !Config.analyzeTypes && not loc_ghost then
      DeadType.addTypeReference ~posTo ~posFrom:locFrom.loc_start
  | Texp_record {fields} ->
    fields
    |> Array.iter (fun (_, record_label_definition) ->
           match record_label_definition with
           | Typedtree.Overridden (_, ({exp_loc} as e))
             when exp_loc.loc_ghost ->
             (* Punned field in OCaml projects has ghost location in expression *)
             let e = {e with exp_loc = {exp_loc with loc_ghost = false}} in
             collectExpr super self e |> ignore
           | _ -> ())
  | _ -> ());
  super.Tast_mapper.expr self e

(*
  type k. is a locally abstract type
  https://caml.inria.fr/pub/docs/manual-ocaml/locallyabstract.html
  it is required because in ocaml >= 4.11 Typedtree.pattern and ADT is converted
  in a GADT
  https://github.com/ocaml/ocaml/commit/312253ce822c32740349e572498575cf2a82ee96
  in short: all branches of pattern matches aren't the same type.
  With this annotation we declare a new type for each branch to allow the
  function to be typed.
  *)
let collectPattern :
    type k. _ -> _ -> k Compat.generalPattern -> k Compat.generalPattern =
 fun super self pat ->
  let posFrom = pat.Typedtree.pat_loc.loc_start in
  (match pat.pat_desc with
  | Typedtree.Tpat_record (cases, _clodsedFlag) ->
    cases
    |> List.iter (fun (_loc, {
#if OCAML_VERSION >= (5, 4, 0)
                              Data_types.lbl_loc
#else
                              Types.lbl_loc
#endif
                                = {loc_start = posTo}}, _pat) ->
           if !Config.analyzeTypes then
             DeadType.addTypeReference ~posFrom ~posTo)
  | _ -> ());
  super.Tast_mapper.pat self pat

let rec getSignature (moduleType : Types.module_type) =
  match moduleType with
  | Mty_signature signature -> signature
  | Mty_functor _ -> (
    match moduleType |> Compat.getMtyFunctorModuleType with
    | Some (_, mt) -> getSignature mt
    | _ -> [])
  | _ -> []

let nth_opt items index =
  if index < 0 then None else try Some (List.nth items index) with _ -> None

let signatureItemName (signatureItem : Types.signature_item) =
  match signatureItem with
  | Types.Sig_value _ ->
    let id, _loc, _kind, _valType = signatureItem |> Compat.getSigValue in
    Some (Ident.name id)
  | Types.Sig_module _ | Types.Sig_modtype _ -> (
    match signatureItem |> Compat.getSigModuleModtype with
    | Some (id, _moduleType, _moduleLoc) -> Some (Ident.name id)
    | None -> None)
  | _ -> None

let findSignatureItem name signature =
  signature
  |> List.find_opt (fun signatureItem ->
         match signatureItemName signatureItem with
         | Some itemName -> itemName = name
         | None -> false)

(* [shape], when known, is the shape of the module the signature items belong
   to; it is used to reference the implementation of an item rather than a
   shared module type item. See [Compat.resolveIdentOccurrences]. *)
let addValueReferenceFromSignatureItem ~locFrom ?shape signatureItem =
  let id, locTo, _kind, _valType = signatureItem |> Compat.getSigValue in
  if not locTo.loc_ghost then
    let locToImpl =
      match shape with
      | Some shape -> !identResolutions.projValue shape (Ident.name id)
      | None -> None
    in
    addRedirect ~locFrom ~locTo ~locToImpl

let projModuleShape ?shape id =
  match shape with
  | Some shape -> !identResolutions.projModule shape (Ident.name id)
  | None -> None

let rec addAllModuleValueReferences ~locFrom ?shape
    (moduleType : Types.module_type) =
  moduleType |> getSignature
  |> List.iter (fun (signatureItem : Types.signature_item) ->
         match signatureItem with
         | Types.Sig_value _ ->
           addValueReferenceFromSignatureItem ~locFrom ?shape signatureItem
         | Types.Sig_module _ | Types.Sig_modtype _ -> (
           match signatureItem |> Compat.getSigModuleModtype with
           | Some (id, moduleType, _moduleLoc) ->
             addAllModuleValueReferences ~locFrom
               ?shape:(projModuleShape ?shape id)
               moduleType
           | None -> ())
         | _ -> ())

let rec addCoercedModuleValueReferences ~locFrom ~coercion ?shape ~actualType
    () =
  let actualSignature = actualType |> getSignature in
  match coercion with
  | Typedtree.Tcoerce_none ->
    addAllModuleValueReferences ~locFrom ?shape actualType
  | Typedtree.Tcoerce_structure (values, modules) ->
    let actualFields =
      actualSignature
      |> List.filter (function
           | Types.Sig_type _ | Types.Sig_module _ | Types.Sig_modtype _ ->
             false
           | _ -> true)
    in
    values
    |> List.iter (fun (index, _coercion) ->
           match nth_opt actualFields index with
           | Some (Types.Sig_value _ as actualItem) ->
             addValueReferenceFromSignatureItem ~locFrom ?shape actualItem
           | Some _ -> ()
           | None -> ());
    let actualModules =
      actualSignature
      |> List.filter (function
           | Types.Sig_module _ | Types.Sig_modtype _ -> true
           | _ -> false)
    in
    modules
    |> List.iter (fun (id, index, coercion) ->
           let actualItem =
             match actualSignature |> findSignatureItem (Ident.name id) with
             | Some item -> Some item
             | None -> nth_opt actualModules index
           in
           match actualItem with
           | Some actualItem -> (
             match actualItem |> Compat.getSigModuleModtype with
             | Some (actualId, actualType, _moduleLoc) ->
               addCoercedModuleValueReferences ~locFrom ~coercion
                 ?shape:(projModuleShape ?shape actualId)
                 ~actualType ()
             | None -> ())
           | None -> ())
  | Typedtree.Tcoerce_alias (_env, _path, coercion) ->
    addCoercedModuleValueReferences ~locFrom ~coercion ?shape ~actualType ()
  | Typedtree.Tcoerce_functor (_argCoercion, resultCoercion) ->
    addCoercedModuleValueReferences ~locFrom ~coercion:resultCoercion ?shape
      ~actualType ()
  | Typedtree.Tcoerce_primitive _ -> ()

let rec processSignatureItem ~doTypes ~doValues ~moduleLoc ~path
    (si : Types.signature_item) =
  match si with
  | Sig_type _ when doTypes ->
    let id, t = si |> Compat.getSigType in
    if !Config.analyzeTypes then
      DeadType.addDeclaration ~typeId:id ~typeKind:t.type_kind
  | Sig_value _ when doValues ->
    let id, loc, kind, valType = si |> Compat.getSigValue in
    if not loc.Location.loc_ghost then
      let isPrimitive = match kind with Val_prim _ -> true | _ -> false in
      if (not isPrimitive) || !Config.analyzeExternals then
        let optionalArgs =
          valType |> DeadOptionalArgs.fromTypeExpr |> OptionalArgs.fromList
        in

        (* if Ident.name id = "someValue" then
           Printf.printf "XXX %s\n" (Ident.name id); *)
        Ident.name id
        |> Name.create ~isInterface:false
        |> addValueDeclaration ~loc ~moduleLoc ~optionalArgs ~path
             ~sideEffects:false
  | Sig_module _ | Sig_modtype _ -> (
    match si |> Compat.getSigModuleModtype with
    | Some (id, moduleType, moduleLoc) ->
      let collect = match si with Sig_modtype _ -> false | _ -> true in
      if collect then
        getSignature moduleType
        |> List.iter
             (processSignatureItem ~doTypes ~doValues ~moduleLoc
                ~path:((id |> Ident.name |> Name.create) :: path))
    | None -> ())
  | _ -> ()

(* Implementation of a value of an actual functor argument, by path. *)
let argumentItemResolver (argumentExpr : Typedtree.module_expr) =
  let shape =
    match argumentExpr.mod_desc with
    | Tmod_ident (path, lid) ->
      !identResolutions.moduleShape lid.loc (Path.last path)
    | _ -> None
  in
  let resolutions = !identResolutions in
  let rec viaShape shape components =
    match components with
    | [] -> None
    | [name] -> resolutions.projValue shape name
    | m :: rest -> (
      match resolutions.projModule shape m with
      | Some shape -> viaShape shape rest
      | None -> None)
  in
  let rec viaSignature (moduleType : Types.module_type) components =
    let signature = moduleType |> getSignature in
    match components with
    | [] -> None
    | [name] -> (
      match signature |> findSignatureItem name with
      | Some (Types.Sig_value _ as item) ->
        let _id, loc, _kind, _valType = item |> Compat.getSigValue in
        if loc.loc_ghost then None else Some loc
      | _ -> None)
    | m :: rest -> (
      match signature |> findSignatureItem m with
      | Some item -> (
        match item |> Compat.getSigModuleModtype with
        | Some (_id, moduleType, _loc) -> viaSignature moduleType rest
        | None -> None)
      | None -> None)
  in
  fun components ->
    match shape with
    | Some shape -> (
      match viaShape shape components with
      | Some loc -> Some loc
      | None -> viaSignature argumentExpr.mod_type components)
    | None -> viaSignature argumentExpr.mod_type components

(* Applications already recorded as part of an outer curried application. *)
let recordedApplications = ref PosSet.empty

(* [F (A) (B)] is [Tmod_apply (Tmod_apply (F, A), B)]: collect the functor and
   the arguments in order, and defer crediting the calls made through each
   parameter to the corresponding argument. *)
let recordFunctorApplication (moduleExpr : Typedtree.module_expr) =
  if not (PosSet.mem moduleExpr.mod_loc.loc_start !recordedApplications) then
    let rec flatten (e : Typedtree.module_expr) args =
      match e.mod_desc with
      | Tmod_apply (functorExpr, argumentExpr, _) ->
        recordedApplications :=
          PosSet.add e.mod_loc.loc_start !recordedApplications;
        flatten functorExpr (argumentExpr :: args)
      | Tmod_ident (path, lid) -> Some (path, lid, args)
      | _ -> None
    in
    match flatten moduleExpr [] with
    | Some (path, lid, args) -> (
      match !identResolutions.moduleDefLoc lid.loc (Path.last path) with
      | Some defLoc ->
        args
        |> List.iteri (fun argIndex argumentExpr ->
               delayedApplications :=
                 {
                   appliedFunctor = defLoc.loc_start;
                   argIndex;
                   resolveItem = argumentItemResolver argumentExpr;
                 }
                 :: !delayedApplications)
      | None -> ())
    | None -> ()

(* Traverse the AST *)
let traverseStructure ~doTypes ~doExternals =
  let super = Tast_mapper.default in
  let expr self e = e |> collectExpr super self in
  let pat self p = p |> collectPattern super self in
  let module_expr self (moduleExpr : Typedtree.module_expr) =
    let oldFunctorParameters = !functorParameters in
    (match moduleExpr.mod_desc with
    | Tmod_functor (Named (Some id, _, _), _) ->
      let functorDef = !currentModuleBindingPos in
      let paramIndex =
        !functorParameters
        |> List.filter (fun p -> p.functorDef = functorDef)
        |> List.length
      in
      functorParameters :=
        {paramId = id; functorDef; paramIndex} :: !functorParameters
    | _ -> ());
    (match moduleExpr.mod_desc with
    | Tmod_apply (_functorExpr, argumentExpr, coercion) ->
      (* Functor arguments are used through the parameter coercion, not every
         value exposed by the actual argument module. When the argument is a
         module path, its shape lets the references target that module's
         implementation rather than a shared module type item. *)
      let shape =
        match argumentExpr.mod_desc with
        | Tmod_ident (path, lid) ->
          !identResolutions.moduleShape lid.loc (Path.last path)
        | _ -> None
      in
      addCoercedModuleValueReferences ~locFrom:argumentExpr.mod_loc ~coercion
        ?shape ~actualType:argumentExpr.mod_type ();
      recordFunctorApplication moduleExpr
    | _ -> ());
    let r = super.Tast_mapper.module_expr self moduleExpr in
    functorParameters := oldFunctorParameters;
    r
  in
  let value_binding self vb = vb |> collectValueBinding super self in
  let structure_item self (structureItem : Typedtree.structure_item) =
    let oldModulePath = ModulePath.getCurrent () in
    let oldModuleBindingPos = !currentModuleBindingPos in
    (match structureItem.str_desc with
    | Tstr_module {mb_expr; mb_id; mb_loc; mb_name} -> (
      currentModuleBindingPos := mb_name.loc.loc_start;
      let hasInterface =
        match mb_expr.mod_desc with Tmod_constraint _ -> true | _ -> false
      in
      ModulePath.setCurrent
        {
          oldModulePath with
          loc = mb_loc;
          path =
            (mb_id |> Compat.moduleIdName |> Name.create) :: oldModulePath.path;
        };
      if hasInterface then
        match mb_expr.mod_type with
        | Mty_signature signature ->
          signature
          |> List.iter
               (processSignatureItem ~doTypes ~doValues:false
                  ~moduleLoc:mb_expr.mod_loc
                  ~path:
                    ((ModulePath.getCurrent ()).path
                    @ [!Common.currentModuleName]))
        | _ -> ())
    | Tstr_primitive vd when doExternals && !Config.analyzeExternals ->
      let currentModulePath = ModulePath.getCurrent () in
      let path = currentModulePath.path @ [!Common.currentModuleName] in
      let exists =
        match PosHash.find_opt decls vd.val_loc.loc_start with
        | Some {declKind = Value _} -> true
        | _ -> false
      in
      let id = vd.val_id |> Ident.name in
      Printf.printf "Primitive %s\n" id;
      if
        (not exists) && id <> "unsafe_expr"
        (* see https://github.com/BuckleScript/bucklescript/issues/4532 *)
      then
        id
        |> Name.create ~isInterface:false
        |> addValueDeclaration ~path ~loc:vd.val_loc
             ~moduleLoc:currentModulePath.loc ~sideEffects:false
    | Tstr_type (_recFlag, typeDeclarations) when doTypes ->
      if !Config.analyzeTypes then
        typeDeclarations
        |> List.iter (fun (typeDeclaration : Typedtree.type_declaration) ->
               DeadType.addDeclaration ~typeId:typeDeclaration.typ_id
                 ~typeKind:typeDeclaration.typ_type.type_kind)
    | Tstr_include {incl_mod; incl_type} -> (
      match incl_mod.mod_desc with
      | Tmod_ident (_path, _lid) ->
        let currentPath =
          (ModulePath.getCurrent ()).path @ [!Common.currentModuleName]
        in
        incl_type
        |> List.iter
             (processSignatureItem ~doTypes
                ~doValues:false (* TODO: also values? *)
                ~moduleLoc:incl_mod.mod_loc ~path:currentPath)
      | _ -> ())
    | Tstr_exception _ -> (
      match structureItem.str_desc |> Compat.tstrExceptionGet with
      | Some (id, loc) ->
        let path =
          (ModulePath.getCurrent ()).path @ [!Common.currentModuleName]
        in
        let name = id |> Ident.name |> Name.create in
        name |> DeadException.add ~path ~loc ~strLoc:structureItem.str_loc
      | None -> ())
    | _ -> ());
    let result = super.structure_item self structureItem in
    ModulePath.setCurrent oldModulePath;
    currentModuleBindingPos := oldModuleBindingPos;
    result
  in
  {super with expr; module_expr; pat; structure_item; value_binding}

(* Merge a location's references to another one's *)
let processValueDependency
  ( ({loc_start = {pos_fname = fnTo} as posTo; loc_ghost = ghost1} as
          locTo :
      Location.t),
    ({loc_start = {pos_fname = fnFrom} as posFrom; loc_ghost = ghost2} as
          locFrom :
      Location.t) ) =
  if (not ghost1) && (not ghost2) && posTo <> posFrom then
    match PosHash.find_opt decls posFrom with
    | None ->
      (* The signature item is not a declaration (e.g. a [val] inside a named
         module type used to constrain a module or functor result), so it can
         never be resolved as dead. Forward the references made to the
         signature item onto the implementation instead. Occurrences resolved
         through shapes already point at the implementation and are not in
         this set; this is the conservative fallback for the rest, and keeps
         every implementation of the item live. *)
      DeadOptionalArgs.forwardDelayedItems ~posFrom ~posTo;
      ValueReferences.find posFrom
      |> PosSet.iter (fun posRef ->
             if
               posRef <> posTo
               && not
                    (PosPairSet.mem (posFrom, posRef)
                       !nonForwardableReferences)
             then
               let locRef =
                 {
                   Location.loc_start = posRef;
                   loc_end = posRef;
                   loc_ghost = false;
                 }
               in
               addValueReference ~addFileReference:true ~locFrom:locRef ~locTo)
    | Some _ ->
      let addFileReference = fileIsImplementationOf fnTo fnFrom in
      addValueReference ~addFileReference ~locFrom ~locTo;
      DeadOptionalArgs.addFunctionReference ~locFrom ~locTo

(* Value dependencies are processed once all files have been scanned, so that
   declarations and references from every file are known. *)
let delayedValueDependencies = ref []

let forceDelayedItems () =
  let redirects = List.rev !delayedRedirects in
  delayedRedirects := [];
  redirects
  |> List.iter (fun {locFrom; locTo; locToImpl} ->
         let locTo =
           match PosHash.find_opt decls locTo.loc_start with
           | Some _ -> locTo
           | None -> locToImpl
         in
         addValueReference ~addFileReference:true ~locFrom ~locTo);
  (* Credit calls made through functor parameters to the actual arguments. *)
  let applications = List.rev !delayedApplications in
  delayedApplications := [];
  applications
  |> List.iter (fun {appliedFunctor; argIndex; resolveItem} ->
         Hashtbl.iter
           (fun (def, index, components) calls ->
             if def = appliedFunctor && index = argIndex then
               match resolveItem components with
               | Some (locTo : Location.t) ->
                 calls
                 |> List.iter
                      (DeadOptionalArgs.addCallToImplementation
                         ~posTo:locTo.loc_start)
               | None -> ())
           parameterCalls);
  DeadOptionalArgs.settleDelayedItems ();
  let dependencies = List.rev !delayedValueDependencies in
  delayedValueDependencies := [];
  dependencies |> List.iter processValueDependency

let processStructure ~cmt_value_dependencies ~cmt_ident_resolutions ~doTypes
    ~doExternals (structure : Typedtree.structure) =
  let traverseStructure = traverseStructure ~doTypes ~doExternals in
  identResolutions := cmt_ident_resolutions;
  structure |> traverseStructure.structure traverseStructure |> ignore;
  identResolutions := Compat.emptyIdentResolutions;
  let valueDependencies = cmt_value_dependencies |> List.rev in
  delayedValueDependencies :=
    List.rev_append valueDependencies !delayedValueDependencies
