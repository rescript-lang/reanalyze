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
  prefix : string list;
      (** for an alias of (a submodule of) a parameter, [module N = M.Sub],
          the path from the parameter: ["Sub"] *)
  paramType : Types.module_type option;
      (** the parameter's declared module type, for module types rooted at
          the parameter ([module type T = M.T]) *)
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

type argumentResolver =
  | Direct of (string list -> Location.t option)
      (** implementation of a value of the actual argument, by path *)
  | ViaParameter of Lexing.position * int * string list
      (** the argument is (a submodule of) a parameter of the enclosing
          functor: resolved through that functor's own applications *)

type delayedApplication = {
  appliedFunctor : Lexing.position;
  argIndex : int;
  resolver : argumentResolver;
}

let delayedApplications : delayedApplication list ref = ref []

(* Implementations of a value of the argument at [argIndex] of every
   application of the functor keyed [functorDef]. *)
let rec resolveArgumentItems ~visited functorDef argIndex components =
  if List.mem (functorDef, argIndex) visited then []
  else
    let visited = (functorDef, argIndex) :: visited in
    !delayedApplications
    |> List.concat_map (fun {appliedFunctor; argIndex = index; resolver} ->
           if appliedFunctor <> functorDef || index <> argIndex then []
           else
             match resolver with
             | Direct resolve -> (
               match resolve components with Some loc -> [loc] | None -> [])
             | ViaParameter (outerDef, outerIndex, prefix) ->
               resolveArgumentItems ~visited outerDef outerIndex
                 (prefix @ components))

(* Coercion references made through a functor parameter, as in
   [module Outer (M : S) = Inner (M)]: credited to the arguments of the
   enclosing functor's applications, once all files are scanned. *)
type parameterCoercion = {
  outerFunctor : Lexing.position;
  outerIndex : int;
  itemPath : string list;
  coercionFrom : Location.t;
  coercionTo : Location.t;  (** the module type item, as fallback *)
}

let parameterCoercions : parameterCoercion list ref = ref []

(* A module expression under any [( M : S )] constraints. *)
let rec unwrapConstraints (moduleExpr : Typedtree.module_expr) =
  match moduleExpr.mod_desc with
  | Tmod_constraint (inner, _, _, _) -> unwrapConstraints inner
  | _ -> moduleExpr

(* The module path an argument or functor expression denotes, through any
   [( M : S )] constraints. *)
let rec moduleIdent (moduleExpr : Typedtree.module_expr) =
  match moduleExpr.mod_desc with
  | Tmod_ident (path, lid) -> Some (path, lid)
  | Tmod_constraint (inner, _, _, _) -> moduleIdent inner
  | _ -> None

(* Keys of functor expressions, by node identity: the module binding's name
   for named functors, and the enclosing functor's key for curried parameters.
   Functors not listed (inline applications) are keyed by their own position.
   A list rather than a single slot, as the mapper may visit a binding's body
   (and the bindings nested in it) before its module expression. *)
let functorKeys : (Typedtree.module_expr * Lexing.position) list ref = ref []

let setFunctorKey (moduleExpr : Typedtree.module_expr) pos =
  functorKeys := (moduleExpr, pos) :: !functorKeys

(* Keys are positions, since applications only learn a definition through
   its declaration's location (possibly in another file). Two distinct
   definitions a ppx emitted at one position therefore share a key: the
   calls through either's parameters are credited to the arguments of every
   application of that key, which is tighter than forwarding to every
   implementation and never hides a supplied argument. *)

let findFunctorKey (moduleExpr : Typedtree.module_expr) =
  match List.find_opt (fun (e, _) -> e == moduleExpr) !functorKeys with
  | Some (_, pos) -> Some pos
  | None -> None

(* Functors that applications in the same file cannot find by uid, keyed by
   identifier: [let module] bindings (not registered as declarations before
   OCaml 5.5) and recursive modules (whose occurrences have no uid). *)
let functorsByIdent : (Ident.t * (Lexing.position * int)) list ref = ref []

let rec pathComponents (path : Path.t) =
  match path with
  | Pident _ -> Some []
  | Pdot (p, name) -> (
    match pathComponents p with
    | Some comps -> Some (comps @ [name])
    | None -> None)
  | _ -> None

(* [module N = M] or [module N = M.Sub] inside a functor body, where [M] is a
   parameter: [N] then stands for the parameter too. *)
let registerParameterAlias (id : Ident.t option)
    (moduleExpr : Typedtree.module_expr) =
  let rec ident (e : Typedtree.module_expr) =
    match e.mod_desc with
    | Tmod_ident (path, _) -> Some path
    | Tmod_constraint (inner, _, _, _) -> ident inner
    | _ -> None
  in
  match (id, ident moduleExpr) with
  | Some id, Some path -> (
    match (findFunctorParameter path, pathComponents path) with
    | Some p, Some components ->
      if !Common.Cli.debug then
        Log_.item "parameterAlias %s = %s (prefix %s)@." (Ident.unique_name id)
          (Path.name path)
          (String.concat "." (p.prefix @ components));
      functorParameters :=
        {p with paramId = id; prefix = p.prefix @ components}
        :: !functorParameters
    | _ -> ())
  | _ -> ()

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
    | Some {functorDef; paramIndex; prefix}, Some components ->
      let components = prefix @ components in
      let key = (functorDef, paramIndex, components) in
      if !Common.Cli.debug then
        Log_.item "parameterCall %s functor:%s index:%d@."
          (String.concat "." components)
          (functorDef |> posToString)
          paramIndex;
      let calls =
        match Hashtbl.find_opt parameterCalls key with
        | Some calls -> calls
        | None -> []
      in
      Hashtbl.replace parameterCalls key (call :: calls)
    | _ -> ());
    call
    |> DeadOptionalArgs.addReferences ~locFrom ~locTo ?locToImpl
         ~forwardable:(parameter = None || not Compat.shapeResolutionAvailable)
         ~path)

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
  (if isFunctorParameterPath path && Compat.shapeResolutionAvailable then
     nonForwardableReferences := PosPairSet.add pair !nonForwardableReferences
   else if locToImpl = None && PosPairSet.mem pair !nonForwardableReferences
   then
     (* A non-parameter reference from the same position that stays targeted
        at the module type item keeps the pair forwardable. A redirected one
        does not: it never lands on the item. *)
     nonForwardableReferences := PosPairSet.remove pair !nonForwardableReferences);
  addRedirect ~locFrom ~locTo ~locToImpl

(* The shape of a module expression used as a functor argument: a module
   path's, or that of an application ([Use (Make (A))]), built from the
   functor's and the argument's as the compiler does. *)
let rec moduleShapeOfExpr (moduleExpr : Typedtree.module_expr) =
  match moduleExpr.mod_desc with
  | Tmod_ident (path, _)
    when Compat.shapeResolutionAvailable && isFunctorParameterPath path ->
    Some Compat.parameterShape
  | Tmod_ident (path, lid) ->
    !identResolutions.moduleShape lid.loc (Path.last path)
  | Tmod_constraint (inner, _, _, _) -> moduleShapeOfExpr inner
  | Tmod_apply (functorExpr, argumentExpr, _) -> (
    match (moduleShapeOfExpr functorExpr, moduleShapeOfExpr argumentExpr) with
    | Some functorShape, Some argumentShape ->
      Some (Compat.applyShape functorShape argumentShape)
    | _ -> None)
#if OCAML_VERSION >= (5, 1, 0)
  | Tmod_apply_unit functorExpr -> (
    match moduleShapeOfExpr functorExpr with
    | Some functorShape -> Some (Compat.applyUnitShape functorShape)
    | None -> None)
#endif
  | _ -> None

(* The key of the functor a module expression denotes, and the number of
   arguments already consumed by partial applications it stands for, as in
   [module G = F (A)] followed by [G (B)]. Aliases ([module G = F]) are
   chased within the current file. *)
let rec functorKeyOfHead (e : Typedtree.module_expr) =
    match e.mod_desc with
    | Tmod_apply (functorExpr, _, _) -> (
      match functorKeyOfHead functorExpr with
      | Some (key, consumed) -> Some (key, consumed + 1)
      | None -> None)
#if OCAML_VERSION >= (5, 1, 0)
    | Tmod_apply_unit functorExpr -> (
      (* [F ()]: the unit parameter occupies an index. *)
      match functorKeyOfHead functorExpr with
      | Some (key, consumed) -> Some (key, consumed + 1)
      | None -> None)
#endif
    | Tmod_constraint (inner, _, _, _) -> functorKeyOfHead inner
    | Tmod_functor _ ->
      (* Inline functor: keyed by its own position, see [functorKeys]. *)
      Some (e.mod_loc.loc_start, 0)
    | Tmod_ident (path, _lid) -> (
      let byIdent () =
        match
          List.find_opt
            (fun (id, _) -> Ident.same id (Path.head path))
            !functorsByIdent
        with
        | Some (_, key) -> Some key
        | None -> None
        | exception _ -> None
      in
      match !identResolutions.headKey Compat.noHeadVisited e with
      | Some (nameLoc, consumed) -> Some (nameLoc.loc_start, consumed)
      | None -> byIdent ())
    | _ -> None

let rec collectExpr super self (e : Typedtree.expression) =
  let locFrom = e.exp_loc in
  (* [let module F (M : S) = ... in]: key the functor by its binding. On
     OCaml >= 5.5 this is a [Texp_struct_item] holding a [Tstr_module], which
     the structure item handler covers. *)
  #if OCAML_VERSION >= (5, 5, 0)
  (* The mapper visits the body of a [let module] before the binding, so an
     alias of a parameter must be registered here for uses in the body. The
     structure item handler registers it again, harmlessly. *)
  (match e.exp_desc with
  | Texp_struct_item ({str_desc = Tstr_module {mb_id; mb_expr}}, _) ->
    registerParameterAlias mb_id mb_expr
  | _ -> ());
  #else
  (match e.exp_desc with
  | Texp_letmodule (id, name, _, moduleExpr, _) ->
    setFunctorKey moduleExpr name.loc.loc_start;
    registerParameterAlias id moduleExpr;
    (match id with
    | Some id ->
      (* [let module G = F in] or [let module G = F (A) in]: G stands for
         F's key, with the arguments already consumed. *)
      let key =
        match (unwrapConstraints moduleExpr).mod_desc with
        | Tmod_functor _ -> (name.loc.loc_start, 0)
        | _ -> (
          match functorKeyOfHead moduleExpr with
          | Some key -> key
          | None -> (name.loc.loc_start, 0))
      in
      functorsByIdent := (id, key) :: !functorsByIdent
    | None -> ())
  | _ -> ());
  #endif
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

(* The value items a module coercion uses, with the path of submodules
   leading to each. *)
(* Module type expansion, also for module types rooted at a functor
   parameter in scope ([module type T = M.T], [M.Sub.T2]): those are found in
   the parameter's declared module type. *)
let rec expandModuleType ?(visited = []) (moduleType : Types.module_type) =
  let expanded = !identResolutions.expandModuleType moduleType in
  match expanded with
  | Mty_ident path when not (List.exists (Path.same path) visited) -> (
    let visited = path :: visited in
    match moduleTypeViaParameter ~visited path with
    | Some moduleType -> expandModuleType ~visited moduleType
    | None -> expanded)
  | _ -> expanded

and moduleTypeViaParameter ~visited (path : Path.t) =
  match (findFunctorParameter path, pathComponents path) with
  | Some {paramType = Some paramType; prefix}, Some components -> (
    let rec walk (moduleType : Types.module_type) components =
      let signature = moduleType |> expandModuleType ~visited |> getSignature in
      match components with
      | [] -> None
      | [name] -> (
        match signature |> findSignatureItem name with
        | Some (Types.Sig_modtype _ as item) -> (
          match item |> Compat.getSigModuleModtype with
          | Some (_, moduleType, _) -> Some moduleType
          | None -> None)
        | _ -> None)
      | m :: rest -> (
        match signature |> findSignatureItem m with
        | Some (Types.Sig_module _ as item) -> (
          match item |> Compat.getSigModuleModtype with
          | Some (_, moduleType, _) -> walk moduleType rest
          | None -> None)
        | _ -> None)
    in
    walk paramType (prefix @ components))
  | _ -> None

(* Signature of a module type, with aliases of named module types expanded
   ([module N : Other.O] inside a signature is [Mty_ident] in the typed tree,
   which exposes no items). Only runtime modules ([Sig_module]) are walked:
   a [Sig_modtype] declaration has no fields. *)
let expandedSignature (moduleType : Types.module_type) =
  moduleType |> expandModuleType |> getSignature

(* The location of a value in a module type, by path of names. *)
let rec findValueInModuleType (moduleType : Types.module_type) components =
  let signature = moduleType |> expandedSignature in
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
    | Some (Types.Sig_module _ as item) -> (
      match item |> Compat.getSigModuleModtype with
      | Some (_id, moduleType, _loc) -> findValueInModuleType moduleType rest
      | None -> None)
    | _ -> None)

let rec iterAllModuleValues ~path (moduleType : Types.module_type) f =
  moduleType |> expandedSignature
  |> List.iter (fun (signatureItem : Types.signature_item) ->
         match signatureItem with
         | Types.Sig_value _ -> f ~path signatureItem
         | Types.Sig_module _ -> (
           match signatureItem |> Compat.getSigModuleModtype with
           | Some (id, moduleType, _moduleLoc) ->
             iterAllModuleValues ~path:(path @ [Ident.name id]) moduleType f
           | None -> ())
         | _ -> ())

let rec iterCoercedValues ~path ~coercion ~actualType f =
  let actualSignature = actualType |> expandedSignature in
  match coercion with
  | Typedtree.Tcoerce_none -> iterAllModuleValues ~path actualType f
  | Typedtree.Tcoerce_structure (fields, _idPositions) ->
    (* [fields] has one entry per runtime component of the target, giving
       the position in the source's runtime fields and the coercion of that
       component; submodules recurse with theirs. The second list only maps
       source module identifiers to positions, for aliases. *)
    let runtimeFields = actualSignature |> List.filter Compat.isRuntimeField in
    fields
    |> List.iter (fun (index, coercion) ->
           match nth_opt runtimeFields index with
           | Some (Types.Sig_value _ as actualItem) -> f ~path actualItem
           | Some (Types.Sig_module _ as actualItem) -> (
             match actualItem |> Compat.getSigModuleModtype with
             | Some (actualId, actualType, _moduleLoc) ->
               iterCoercedValues
                 ~path:(path @ [Ident.name actualId])
                 ~coercion ~actualType f
             | None -> ())
           | _ -> ())
  | Typedtree.Tcoerce_alias (_env, _path, coercion) ->
    iterCoercedValues ~path ~coercion ~actualType f
  | Typedtree.Tcoerce_functor (_argCoercion, resultCoercion) ->
    iterCoercedValues ~path ~coercion:resultCoercion ~actualType f
  | Typedtree.Tcoerce_primitive _ -> ()

(* Reference the values a functor argument's coercion uses. [shape], when
   known, is the argument module's shape: items are then redirected to their
   implementation rather than to a shared module type item. *)
let addCoercedModuleValueReferences ~locFrom ~coercion ?shape ?concrete
    ~actualType () =
  (match (expandedSignature actualType, shape) with
  | [], Some shape ->
    (* The argument's signature could not be expanded (a module type this
       analysis cannot resolve): reference the values its shape exports
       instead, which is precise to this argument. *)
    !identResolutions.shapeValueItems shape
    |> List.iter (fun (_, locTo) ->
           addValueReference ~addFileReference:true ~locFrom ~locTo)
  | _ -> ());
  iterCoercedValues ~path:[] ~coercion ~actualType (fun ~path signatureItem ->
      let id, locTo, _kind, _valType = signatureItem |> Compat.getSigValue in
      if not locTo.loc_ghost then
        let resolutions = !identResolutions in
        let itemShape =
          path
          |> List.fold_left
               (fun shape name ->
                 match shape with
                 | Some shape -> resolutions.projModule shape name
                 | None -> None)
               shape
        in
        let locToImpl =
          match itemShape with
          | Some shape -> resolutions.projValue shape (Ident.name id)
          | None -> None
        in
        let locToImpl =
          match (locToImpl, concrete) with
          | None, Some concrete ->
            findValueInModuleType concrete (path @ [Ident.name id])
          | _ -> locToImpl
        in
        addRedirect ~locFrom ~locTo ~locToImpl)

(* Same, when the argument is a functor parameter: deferred to the arguments
   of the enclosing functor's applications. *)
let recordParameterCoercion ~locFrom ~coercion ~actualType
    (parameter : functorParameter) components =
  iterCoercedValues ~path:[] ~coercion ~actualType (fun ~path signatureItem ->
      let id, locTo, _kind, _valType = signatureItem |> Compat.getSigValue in
      if not locTo.loc_ghost then
        parameterCoercions :=
          {
            outerFunctor = parameter.functorDef;
            outerIndex = parameter.paramIndex;
            itemPath = parameter.prefix @ components @ path @ [Ident.name id];
            coercionFrom = locFrom;
            coercionTo = locTo;
          }
          :: !parameterCoercions)

(* Whether a value item of a file's signature is a definition of that file.
   Items whose location lies in another file, or inside a [module type] of the
   file, come from [include]s (e.g. [include T] of a functor parameter, whose
   items point at the module type's [val]s): they are not declarations. *)
let isSignatureValueDeclaration = ref (fun (_ : Location.t) -> true)

let setSignatureValueFilter ~(fileName : string) ~(buildDir : string)
    ~(moduleTypeRanges : Location.t list) =
  (* Full paths resolved against the build directory the compiler ran in
     (both the recorded source file and positions are relative to it), and
     compared exactly, without extensions (a preprocessed source is recorded
     as [foo.pp.ml] while its positions say [foo.ml]). Basenames or suffixes
     alone would confuse same-named sources in different directories. *)
  let normalize path =
    let path =
      if Filename.is_relative path then Filename.concat buildDir path else path
    in
    let base =
      match String.index_opt (Filename.basename path) '.' with
      | Some i -> String.sub (Filename.basename path) 0 i
      | None -> Filename.basename path
    in
    (* Drop [.] segments and resolve [..], which one side may carry; both
       separators, as Windows paths may carry either. *)
    let segments =
      String.split_on_char '/'
        (String.map
           (fun c -> if c = '\\' then '/' else c)
           (Filename.dirname path))
      |> List.fold_left
           (fun acc segment ->
             match (segment, acc) with
             | ".", _ -> acc
             | "..", _ :: rest -> rest
             | _ -> segment :: acc)
           []
      |> List.rev
    in
    String.concat "/" (segments @ [base])
  in
  let self = normalize fileName in
  isSignatureValueDeclaration :=
    fun (loc : Location.t) ->
      let sameFile = normalize loc.loc_start.pos_fname = self in
      if (not sameFile) && !Common.Cli.debug then
        Log_.item "signatureValueSkipped %s (file %s)@."
          (loc.loc_start |> posToString)
          fileName;
      sameFile
      && not
           (moduleTypeRanges
           |> List.exists (fun (range : Location.t) ->
                  range.loc_start.pos_cnum <= loc.loc_start.pos_cnum
                  && loc.loc_start.pos_cnum < range.loc_end.pos_cnum))

let rec processSignatureItem ~doTypes ~doValues ~moduleLoc ~path
    (si : Types.signature_item) =
  match si with
  | Sig_type _ when doTypes ->
    let id, t = si |> Compat.getSigType in
    if !Config.analyzeTypes then
      DeadType.addDeclaration ~typeId:id ~typeKind:t.type_kind
  | Sig_value _ when doValues ->
    let id, loc, kind, valType = si |> Compat.getSigValue in
    if (not loc.Location.loc_ghost) && !isSignatureValueDeclaration loc then
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

(* The type of a functor argument, with an explicit constraint by a named
   module type [(M : Other.S)] expanded to that module type's signature: the
   typed tree leaves it as [Mty_ident], which exposes no items. *)
let rec argumentModuleType (argumentExpr : Typedtree.module_expr) =
  let expand moduleType = expandModuleType moduleType in
  match (argumentExpr.mod_desc, argumentExpr.mod_type) with
  | ( Tmod_constraint
        (_, _, Tmodtype_explicit {mty_desc = Tmty_ident (path, lid)}, _),
      Mty_ident _ ) -> (
    match !identResolutions.moduleTypeOf lid.loc (Path.last path) with
    | Some moduleType -> expand moduleType
    | None -> expand argumentExpr.mod_type)
  | Tmod_constraint (inner, _, _, _), Mty_ident _ -> argumentModuleType inner
  | _ -> expand argumentExpr.mod_type

(* A more concrete type of an argument than its own, when the expression
   shows one: the type of the module under [( _ : S )] constraints, and for an
   application of an inline functor, the type of the functor's body. Its
   items are the same runtime fields as the argument's, so a value the
   argument's signature only names (a shared module type item) is found there
   by name; when the argument's own type cannot be expanded at all (a module
   type outside the analysis root), callers reference all of its values. *)
let rec concreteArgumentType (argumentExpr : Typedtree.module_expr) =
  (* The body of an inline functor at the head of an application chain. *)
  let rec appliedBody (e : Typedtree.module_expr) applied =
    match e.mod_desc with
    | Tmod_constraint (inner, _, _, _) -> appliedBody inner applied
    | Tmod_apply (functorExpr, _, _) -> appliedBody functorExpr (applied + 1)
#if OCAML_VERSION >= (5, 1, 0)
    | Tmod_apply_unit functorExpr -> appliedBody functorExpr (applied + 1)
#endif
    | Tmod_functor (_, body) when applied > 0 -> appliedBody body (applied - 1)
    | Tmod_functor _ | Tmod_ident _ -> None
    | _ when applied = 0 -> Some e
    | _ -> None
  in
  let concrete (inner : Typedtree.module_expr) =
    match concreteArgumentType inner with
    | Some moduleType -> Some moduleType
    | None -> (
      let moduleType = expandModuleType inner.mod_type in
      match getSignature moduleType with [] -> None | _ -> Some moduleType)
  in
  match argumentExpr.mod_desc with
  | Tmod_constraint (inner, _, _, _) -> concrete inner
  | Tmod_apply _
#if OCAML_VERSION >= (5, 1, 0)
  | Tmod_apply_unit _
#endif
    -> (
    match appliedBody argumentExpr 0 with
    | Some body -> concrete body
    | None -> None)
  | _ -> None

(* Implementation of a value of an actual functor argument, by path. *)
let argumentItemResolver (argumentExpr : Typedtree.module_expr) =
  match moduleIdent argumentExpr with
  | Some (path, _)
    when Compat.shapeResolutionAvailable && isFunctorParameterPath path -> (
    match (findFunctorParameter path, pathComponents path) with
    | Some p, Some components ->
      ViaParameter (p.functorDef, p.paramIndex, p.prefix @ components)
    | _ -> Direct (fun _ -> None))
  | _ ->
  let shape = moduleShapeOfExpr argumentExpr in
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
  let declared = argumentModuleType argumentExpr in
  let concrete = concreteArgumentType argumentExpr in
  (* By shape, then by name in the concrete type, then in the declared
     one (a shared module type item, forwarded to its implementations). *)
  let firstSome resolvers components =
    resolvers
    |> List.fold_left
         (fun acc resolve ->
           match acc with Some _ -> acc | None -> resolve components)
         None
  in
  Direct
    (firstSome
       [
         (fun components ->
           match shape with
           | Some shape -> viaShape shape components
           | None -> None);
         (fun components ->
           match concrete with
           | Some concrete -> findValueInModuleType concrete components
           | None -> None);
         findValueInModuleType declared;
       ])

(* Applications already recorded as part of an outer curried application,
   by node identity (a ppx may emit distinct applications at one position). *)
let recordedApplications : Typedtree.module_expr list ref = ref []

(* [F (A) (B)] is [Tmod_apply (Tmod_apply (F, A), B)]: collect the functor and
   the arguments in order, and defer crediting the calls made through each
   parameter to the corresponding argument. *)
let recordFunctorApplication (moduleExpr : Typedtree.module_expr) =
  if not (List.memq moduleExpr !recordedApplications) then
    (* The arguments of this application chain, in order, and its head. A
       unit application ([F ()]) consumes an index without an argument. *)
    let rec flatten (e : Typedtree.module_expr) args =
      match e.mod_desc with
      | Tmod_apply (functorExpr, argumentExpr, _) ->
        recordedApplications := e :: !recordedApplications;
        flatten functorExpr (Some argumentExpr :: args)
#if OCAML_VERSION >= (5, 1, 0)
      | Tmod_apply_unit functorExpr ->
        recordedApplications := e :: !recordedApplications;
        flatten functorExpr (None :: args)
#endif
      | Tmod_constraint (inner, _, _, _) -> flatten inner args
      | _ -> (e, args)
    in
    let head, args = flatten moduleExpr [] in
    let key = functorKeyOfHead head in
    if !Common.Cli.debug then
      Log_.item "functorApplication %s key:%s args:%d@."
        (moduleExpr.mod_loc.loc_start |> posToString)
        (match key with
        | Some (pos, consumed) ->
          Printf.sprintf "%s+%d" (pos |> posToString) consumed
        | None -> "none")
        (List.length args);
    match key with
    | Some (key, consumed) ->
      args
      |> List.iteri (fun i argumentExpr ->
             match argumentExpr with
             | Some argumentExpr ->
               delayedApplications :=
                 {
                   appliedFunctor = key;
                   argIndex = consumed + i;
                   resolver = argumentItemResolver argumentExpr;
                 }
                 :: !delayedApplications
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
    | Tmod_constraint (inner, _, _, _) -> (
      (* [module F : FT = functor ...]: carry the binding's key through. *)
      match findFunctorKey moduleExpr with
      | Some pos -> setFunctorKey inner pos
      | None -> ())
    | Tmod_functor (param, body) ->
      let functorDef =
        match findFunctorKey moduleExpr with
        | Some pos -> pos
        | None -> moduleExpr.mod_loc.loc_start
      in
      setFunctorKey body functorDef;
      let paramIndex =
        !functorParameters
        |> List.filter (fun p -> p.functorDef = functorDef)
        |> List.length
      in
      (match param with
      | Named (Some id, _, mty) ->
        functorParameters :=
          {
            paramId = id;
            functorDef;
            paramIndex;
            prefix = [];
            paramType = Some mty.mty_type;
          }
          :: !functorParameters
      | _ ->
        (* Unnamed or unit parameter: still occupies an index. *)
        functorParameters :=
          {
            paramId = Ident.create_local "_";
            functorDef;
            paramIndex;
            prefix = [];
            paramType = None;
          }
          :: !functorParameters)
    | _ -> ());
    (match moduleExpr.mod_desc with
    | Tmod_apply (_functorExpr, argumentExpr, coercion) ->
      (* Functor arguments are used through the parameter coercion, not every
         value exposed by the actual argument module. When the argument is a
         module path, its shape lets the references target that module's
         implementation rather than a shared module type item. *)
      let ident = moduleIdent argumentExpr in
      let shape = moduleShapeOfExpr argumentExpr in
      (* A constraint node [(M : S)] can carry a ghost location, which would
         drop the references: use the module path's own location then. *)
      let locFrom =
        match ident with
        | Some (_, lid) when not lid.loc.loc_ghost -> lid.loc
        | _ when not argumentExpr.mod_loc.loc_ghost -> argumentExpr.mod_loc
        | _ -> moduleExpr.mod_loc
      in
      let concrete = concreteArgumentType argumentExpr in
      let actualType, coercion =
        let declared = argumentModuleType argumentExpr in
        match (expandedSignature declared, concrete) with
        | [], Some concrete -> (concrete, Typedtree.Tcoerce_none)
        | _ -> (declared, coercion)
      in
      if !Common.Cli.debug then
        Log_.item "functorArgument %s coercion:%s type:%s items:%d@."
          (argumentExpr.mod_loc.loc_start |> posToString)
          (match coercion with
          | Tcoerce_none -> "none"
          | Tcoerce_structure (vs, ms) ->
            Printf.sprintf "structure(%d values, %d modules)" (List.length vs)
              (List.length ms)
          | Tcoerce_alias _ -> "alias"
          | Tcoerce_functor _ -> "functor"
          | Tcoerce_primitive _ -> "primitive")
          (match actualType with
          | Mty_ident p -> "ident " ^ Path.name p
          | Mty_signature _ -> "signature"
          | Mty_functor _ -> "functor"
          | Mty_alias p -> "alias " ^ Path.name p)
          (List.length (expandedSignature actualType));
      let parameter =
        match ident with
        | Some (path, _) when Compat.shapeResolutionAvailable -> (
          match (findFunctorParameter path, pathComponents path) with
          | Some p, Some components -> Some (p, components)
          | _ -> None)
        | _ -> None
      in
      (match parameter with
      | Some (p, components) ->
        recordParameterCoercion ~locFrom ~coercion ~actualType p components
      | None ->
        addCoercedModuleValueReferences ~locFrom ~coercion ?shape ?concrete
          ~actualType ());
      recordFunctorApplication moduleExpr
#if OCAML_VERSION >= (5, 1, 0)
    | Tmod_apply_unit _ -> recordFunctorApplication moduleExpr
#endif
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
      setFunctorKey mb_expr mb_name.loc.loc_start;
      registerParameterAlias mb_id mb_expr;
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
    | Tstr_recmodule moduleBindings ->
      moduleBindings
      |> List.iter (fun (mb : Typedtree.module_binding) ->
             setFunctorKey mb.mb_expr mb.mb_name.loc.loc_start;
             registerParameterAlias mb.mb_id mb.mb_expr;
             match mb.mb_id with
             | Some id ->
               functorsByIdent :=
                 (id, (mb.mb_name.loc.loc_start, 0)) :: !functorsByIdent
             | None -> ());
      (* [module rec G : T = H and H : T = F]: an alias or partial
         application stands for the functor's key; a forward alias resolves
         once the later binding has, so iterate to a fixed point. *)
      let resolveKeys () =
        moduleBindings
        |> List.fold_left
             (fun changed (mb : Typedtree.module_binding) ->
               match (mb.mb_id, (unwrapConstraints mb.mb_expr).mod_desc) with
               | ( Some id,
                   ( Tmod_apply _ | Tmod_ident _
#if OCAML_VERSION >= (5, 1, 0)
                   | Tmod_apply_unit _
#endif
                     ) ) -> (
                 match functorKeyOfHead mb.mb_expr with
                 | Some key when List.assq_opt id !functorsByIdent <> Some key ->
                   functorsByIdent :=
                     (id, key)
                     :: List.filter
                          (fun (id', _) -> not (Ident.same id id'))
                          !functorsByIdent;
                   true
                 | _ -> changed)
               | _ -> changed)
             false
      in
      let rec fixpoint n = if n > 0 && resolveKeys () then fixpoint (n - 1) in
      fixpoint (List.length moduleBindings);
      (* Likewise for aliases of a functor parameter: [module rec G : S = H
         and H : S = M] registers H first, then G through H. *)
      let registerAliases () =
        moduleBindings
        |> List.fold_left
             (fun changed (mb : Typedtree.module_binding) ->
               match mb.mb_id with
               | Some id when findFunctorParameter (Pident id) = None ->
                 registerParameterAlias mb.mb_id mb.mb_expr;
                 findFunctorParameter (Pident id) <> None || changed
               | _ -> changed)
             false
      in
      let rec aliasFixpoint n =
        if n > 0 && registerAliases () then aliasFixpoint (n - 1)
      in
      aliasFixpoint (List.length moduleBindings)
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
      (* [include M] with [M] a functor parameter: the included identifiers
         stand for the parameter's items. *)
      (match moduleIdent incl_mod with
      | Some (path, _) -> (
        match (findFunctorParameter path, pathComponents path) with
        | Some p, Some components ->
          incl_type
          |> List.iter (fun (item : Types.signature_item) ->
                 match item with
                 | Sig_value _ ->
                   let id, _, _, _ = item |> Compat.getSigValue in
                   functorParameters :=
                     {
                       p with
                       paramId = id;
                       prefix = p.prefix @ components @ [Ident.name id];
                     }
                     :: !functorParameters
                 | Sig_module _ | Sig_modtype _ -> (
                   (* Included modules, and module types ([module type T =
                      T] after [include M]), stand for the parameter's. *)
                   match item |> Compat.getSigModuleModtype with
                   | Some (id, _, _) ->
                     functorParameters :=
                       {
                         p with
                         paramId = id;
                         prefix = p.prefix @ components @ [Ident.name id];
                       }
                       :: !functorParameters
                   | None -> ())
                 | _ -> ())
        | _ -> ())
      | None -> ());
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
  delayedApplications := List.rev !delayedApplications;
  Hashtbl.iter
    (fun (def, index, components) calls ->
      resolveArgumentItems ~visited:[] def index components
      |> List.iter (fun (locTo : Location.t) ->
             calls
             |> List.iter
                  (DeadOptionalArgs.addCallToImplementation
                     ~posTo:locTo.loc_start)))
    parameterCalls;
  (* Reference the items a parameter's coercion uses, in the arguments of the
     enclosing functor's applications; the module type item is the fallback
     when an argument cannot be resolved. *)
  List.rev !parameterCoercions
  |> List.iter
       (fun {outerFunctor; outerIndex; itemPath; coercionFrom; coercionTo} ->
           let resolved =
             resolveArgumentItems ~visited:[] outerFunctor outerIndex itemPath
           in
           let applied =
             !delayedApplications
             |> List.exists (fun {appliedFunctor; argIndex} ->
                    appliedFunctor = outerFunctor && argIndex = outerIndex)
           in
           match resolved with
           | [] when applied ->
             addValueReference ~addFileReference:true ~locFrom:coercionFrom
               ~locTo:coercionTo
           | _ ->
             resolved
             |> List.iter (fun locTo ->
                    addValueReference ~addFileReference:true
                      ~locFrom:coercionFrom ~locTo));
  parameterCoercions := [];
  delayedApplications := [];
  DeadOptionalArgs.settleDelayedItems ();
  let dependencies = List.rev !delayedValueDependencies in
  delayedValueDependencies := [];
  dependencies |> List.iter processValueDependency

let processStructure ~cmt_value_dependencies ~cmt_ident_resolutions ~doTypes
    ~doExternals (structure : Typedtree.structure) =
  let traverseStructure = traverseStructure ~doTypes ~doExternals in
  identResolutions := cmt_ident_resolutions;
  recordedApplications := [];
  functorsByIdent := [];
  functorKeys := [];
  structure |> traverseStructure.structure traverseStructure |> ignore;
  recordedApplications := [];
  functorKeys := [];
  identResolutions := Compat.emptyIdentResolutions;
  let valueDependencies = cmt_value_dependencies |> List.rev in
  delayedValueDependencies :=
    List.rev_append valueDependencies !delayedValueDependencies
