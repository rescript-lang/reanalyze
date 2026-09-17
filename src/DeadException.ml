module CompilerPath = Path

open DeadCommon
open Common

type item = {exceptionPath : Path.t; locFrom : Location.t}

let delayedItems = ref []
let declarations = Hashtbl.create 1
let compilationUnit = ref ""
let moduleAliases = Hashtbl.create 16
let declarationPaths = PosHash.create 16

(* Read explicit aliases from annotations, including wrappers whose source
   is unavailable. Local roots are resolved by identifier, so a nested
   module can alias an outer module despite name shadowing. *)
let registerCompilationUnit (infos : Cmt_format.cmt_infos) =
  compilationUnit := infos.cmt_modname;
  PosHash.clear declarationPaths;
  let unitName = Name.create ~isInterface:false infos.cmt_modname in
  let modulePaths = ref Ident.empty in
  let aliases = ref [] in
  let rec collect ~recurse ~path signature =
    signature
    |> List.iter (fun (item : Types.signature_item) ->
           match item with
           | Sig_module _ -> (
             match Compat.getSigModuleModtype item with
             | Some (id, moduleType, _) ->
               let path = Name.create (Ident.name id) :: path in
               modulePaths := Ident.add id path !modulePaths;
               (match moduleType with
               | Mty_alias target -> aliases := (path, target) :: !aliases
               | Mty_signature signature when recurse ->
                 collect ~recurse ~path signature
               | _ -> ())
             | None -> ())
           | _ -> ())
  in
  (* A named module-type constraint can hide an implementation's aliases
     behind [Mty_ident]. Inspect the concrete body beneath the constraint;
     bindings in separate implementations keep their own identifiers. *)
  let rec collectStructure ~path (structure : Typedtree.structure) =
    collect ~recurse:false ~path structure.str_type;
    structure.str_items
    |> List.iter (fun (item : Typedtree.structure_item) ->
           match item.str_desc with
           | Tstr_module binding -> collectBinding ~path binding
           | Tstr_recmodule bindings ->
             List.iter (collectBinding ~path) bindings
           | Tstr_include incl ->
             collect ~recurse:true ~path incl.incl_type;
             collectInclude ~path incl.incl_mod
           | Tstr_exception _ -> (
             match Compat.tstrExceptionGet item.str_desc with
             | Some (id, loc) ->
               PosHash.replace declarationPaths loc.loc_start
                 (Name.create (Ident.name id) :: path)
             | None -> ())
           | _ -> ())
  and collectBinding ~path (binding : Typedtree.module_binding) =
    match binding.mb_id with
    | Some id ->
      collectModule ~path:(Name.create (Ident.name id) :: path) binding.mb_expr
    | None -> ()
  and collectModule ~path (moduleExpr : Typedtree.module_expr) =
    match moduleExpr.mod_desc with
    | Tmod_structure structure -> collectStructure ~path structure
    | Tmod_constraint (inner, _, _, _) -> collectModule ~path inner
    | Tmod_ident (target, _) -> aliases := (path, target) :: !aliases
    | _ -> (
      match moduleExpr.mod_type with
      | Mty_signature signature -> collect ~recurse:true ~path signature
      | _ -> ())
  and collectInclude ~path (moduleExpr : Typedtree.module_expr) =
    match moduleExpr.mod_desc with
    | Tmod_structure structure -> collectStructure ~path structure
    | Tmod_constraint (inner, _, _, _) -> collectInclude ~path inner
    | _ -> ()
  in
  (match infos.cmt_annots with
  | Implementation structure -> collectStructure ~path:[unitName] structure
  | Interface signature ->
    collect ~recurse:true ~path:[unitName] signature.sig_type
  | _ -> ());
  (* Collect all module bindings first, including recursive groups, before
     resolving local alias roots to their fully qualified paths. *)
  !aliases
  |> List.iter (fun (path, target) ->
         match CompilerPath.flatten target with
         | `Ok (root, fields) ->
           let rootPath =
             if Ident.persistent root then
               Some [Name.create ~isInterface:false (Ident.name root)]
             else
               try Some (Ident.find_same root !modulePaths)
               with Not_found -> None
           in
           rootPath
           |> Option.iter (fun rootPath ->
                  Hashtbl.replace moduleAliases path
                    (List.rev_map Name.create fields @ rootPath))
         | `Contains_apply -> ())

let add ~path ~(loc : Location.t) ~(strLoc : Location.t) name =
  let exceptionPath =
    (* The concrete annotation path also retains recursive module bindings,
       which the general declaration visitor does not put on ModulePath. *)
    match PosHash.find_opt declarationPaths loc.loc_start with
    | Some exceptionPath -> exceptionPath
    | None -> (
      match List.rev (name :: path) with
      | _ :: rest ->
        List.rev (Name.create ~isInterface:false !compilationUnit :: rest)
      | [] -> [])
  in
  Hashtbl.add declarations exceptionPath loc;
  name
  |> addDeclaration_ ~posEnd:strLoc.loc_end ~posStart:strLoc.loc_start
       ~declKind:Exception ~moduleLoc:(ModulePath.getCurrent ()).loc ~path ~loc

(* Resolve outer modules before looking up an alias inside them: a Dune
   wrapper may first expose the unit containing [module X = B.Y]. Resolve
   the target as well, since B or Y can themselves be aliases. *)
let rec resolveModuleAliases ~visited path =
  match path with
  | [] -> Some []
  | name :: rest -> (
    match resolveModuleAliases ~visited rest with
    | None -> None
    | Some rest ->
      let path = name :: rest in
      match Hashtbl.find_opt moduleAliases path with
      | None -> Some path
      | Some target ->
        if List.mem path visited then None
        else resolveModuleAliases ~visited:(path :: visited) target)

let findDeclaration exceptionPath =
  match exceptionPath |> Path.moduleToImplementation with
  | name :: modulePath -> (
    match resolveModuleAliases ~visited:[] modulePath with
    | Some modulePath -> Hashtbl.find_opt declarations (name :: modulePath)
    | None -> None)
  | [] -> None

let forceDelayedItems () =
  let items = !delayedItems |> List.rev in
  delayedItems := [];
  items
  |> List.iter (fun {exceptionPath; locFrom} ->
         match findDeclaration exceptionPath with
         | None -> ()
         | Some locTo ->
           addValueReference ~addFileReference:true ~locFrom ~locTo;
           (* Exception declarations are resolved through type references,
              like the non-delayed case in DeadValue. *)
           if !Config.analyzeTypes then
             TypeReferences.add locTo.loc_start locFrom.loc_start)

let markAsUsed ~(locFrom : Location.t) ~(locTo : Location.t) path_ =
  if locTo.loc_ghost then
    (* Probably defined in another file, delay processing and check at the end *)
    let exceptionPath = path_ |> Path.fromPathT in
    delayedItems := {exceptionPath; locFrom} :: !delayedItems
  else addValueReference ~addFileReference:true ~locFrom ~locTo
