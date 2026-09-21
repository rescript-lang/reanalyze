module CompilerPath = Path
open DeadCommon

(* A module's exported names and its lexical identity are separate: replacing
   an export must not change a binding captured by an earlier alias. *)
type moduleNode = {
  id : int;
  modules : (string, moduleNode) Hashtbl.t;
  exceptions : (string, exceptionBinding) Hashtbl.t;
  mutable alias : CompilerPath.t option;
}

and exceptionBinding =
  | Declaration of Location.t
  | Included of moduleNode
  | OtherConstructor

type compilationUnit = {
  cmtFilePath : string;
  imports : Misc.crcs;
  root : moduleNode;
  mutable bindings : moduleNode Ident.tbl;
  mutable exceptionBindings : exceptionBinding Ident.tbl;
  declarations : Location.t PosHash.t;
}

type item = {
  exceptionPath : CompilerPath.t;
  unit : compilationUnit;
  locFrom : Location.t;
  locTo : Location.t;
}

let delayedItems = ref []
let units = Hashtbl.create 16
let currentUnit = ref None
let nextNode = ref 0

let newModule () =
  incr nextNode;
  {
    id = !nextNode;
    modules = Hashtbl.create 4;
    exceptions = Hashtbl.create 4;
    alias = None;
  }

(* Includes can expose more precise signature facts than an inferred
   forwarding module. Enrich a copy so earlier aliases retain their binding. *)
let copyModule node =
  incr nextNode;
  {
    node with
    id = !nextNode;
    modules = Hashtbl.copy node.modules;
    exceptions = Hashtbl.copy node.exceptions;
  }

let getCompilationUnit ~cmtFilePath (infos : Cmt_format.cmt_infos) =
  let key =
    Compat.cmtUnitKey ~cmtFilePath
      ~isInterface:
        (match infos.cmt_annots with Interface _ -> true | _ -> false)
      infos
  in
  match Hashtbl.find_opt units key with
  | Some unit -> unit
  | None ->
    let unit =
      {
        cmtFilePath;
        imports = infos.cmt_imports;
        root = newModule ();
        bindings = Ident.empty;
        exceptionBindings = Ident.empty;
        declarations = PosHash.create 16;
      }
    in
    Hashtbl.add units key unit;
    let bind parent id node =
      unit.bindings <- Ident.add id node unit.bindings;
      Hashtbl.replace parent.modules (Ident.name id) node
    in
    let bindException parent id binding =
      unit.exceptionBindings <- Ident.add id binding unit.exceptionBindings;
      Hashtbl.replace parent.exceptions (Ident.name id) binding
    in
    let rec collectSignature node signature =
      signature
      |> List.iter (fun (item : Types.signature_item) ->
          match item with
          | Sig_module _ -> (
            match Compat.getSigModuleModtype item with
            | Some (id, moduleType, _) ->
              let child =
                match Hashtbl.find_opt node.modules (Ident.name id) with
                | Some child -> copyModule child
                | None -> newModule ()
              in
              bind node id child;
              collectModuleType child moduleType
            | None -> ())
          | Sig_typext (id, extension, Text_exception, _) ->
            let name = Ident.name id in
            if not (Hashtbl.mem node.exceptions name) then
              Hashtbl.add node.exceptions name (Declaration extension.ext_loc)
          | Sig_typext (id, _, _, _) ->
            Hashtbl.replace node.exceptions (Ident.name id) OtherConstructor
          | _ -> ())
    and collectModuleType node = function
      | Types.Mty_alias target -> node.alias <- Some target
      | Mty_signature signature -> collectSignature node signature
      | _ -> ()
    and collectStructure node (structure : Typedtree.structure) =
      structure.str_items
      |> List.iter (fun (item : Typedtree.structure_item) ->
          match item.str_desc with
          | Tstr_module binding -> collectBinding node binding
          | Tstr_recmodule bindings -> List.iter (collectBinding node) bindings
          | Tstr_include incl ->
            let included = newModule () in
            collectModule included incl.incl_mod;
            (* Includes introduce fresh identifiers. Retain concrete locations
               and explicit signature aliases in each exported binding. *)
            incl.incl_type
            |> List.iter (fun (item : Types.signature_item) ->
                match item with
                | Sig_module _ -> (
                  match Compat.getSigModuleModtype item with
                  | Some (id, moduleType, _) ->
                    let name = Ident.name id in
                    let child =
                      match Hashtbl.find_opt included.modules name with
                      | Some child -> copyModule child
                      | None -> newModule ()
                    in
                    collectModuleType child moduleType;
                    (match (child.alias, included.alias) with
                    | None, Some target ->
                      child.alias <- Some (CompilerPath.Pdot (target, name))
                    | _ -> ());
                    bind node id child
                  | None -> ())
                | Sig_typext (id, _, Text_exception, _) ->
                  (* Keep the source view: its aliases select the declaration's
                     owning unit using that unit's imports and lexical bindings. *)
                  bindException node id (Included included)
                | Sig_typext (id, _, _, _) ->
                  bindException node id OtherConstructor
                | _ -> ())
          | Tstr_typext extension ->
            extension.tyext_constructors
            |> List.iter (fun (constructor : Typedtree.extension_constructor) ->
                (* Extension constructors share the exception export namespace.
                   Keep earlier Ident bindings, but block lookup by this name. *)
                bindException node constructor.ext_id OtherConstructor)
          | Tstr_exception _ -> (
            match Compat.tstrExceptionGet item.str_desc with
            | Some (id, loc) ->
              bindException node id (Declaration loc)
            | None -> ())
          | _ -> ())
    and collectBinding node (binding : Typedtree.module_binding) =
      match binding.mb_id with
      | Some id ->
        let child = newModule () in
        bind node id child;
        collectModule child binding.mb_expr
      | None -> ()
    and collectModule node (expr : Typedtree.module_expr) =
      match expr.mod_desc with
      | Tmod_structure structure -> collectStructure node structure
      | Tmod_constraint (inner, _, _, _) -> collectModule node inner
      | Tmod_ident (target, _) ->
        collectModuleType node expr.mod_type;
        node.alias <- Some target
      | _ -> collectModuleType node expr.mod_type
    in
    (match infos.cmt_annots with
    | Implementation structure ->
      collectStructure unit.root structure;
      (* Expression-local modules do not occur in structure signatures. *)
      let super = Tast_iterator.default_iterator in
      let iterator =
        {
          super with
          expr =
            (fun self expr ->
              Compat.iterExpressionModule
                (fun id moduleExpr ->
                  let node = newModule () in
                  unit.bindings <- Ident.add id node unit.bindings;
                  collectModule node moduleExpr)
                expr;
              super.expr self expr);
        }
      in
      iterator.structure iterator structure
    | Interface signature -> collectSignature unit.root signature.sig_type
    | _ -> ());
    unit

let registerCompilationUnit ~cmtFilePath infos =
  currentUnit := Some (getCompilationUnit ~cmtFilePath infos)

let add ~path ~(loc : Location.t) ~(strLoc : Location.t) name =
  !currentUnit
  |> Option.iter (fun unit ->
      PosHash.replace unit.declarations loc.loc_start loc);
  name
  |> addDeclaration_ ~posEnd:strLoc.loc_end ~posStart:strLoc.loc_start
       ~declKind:Exception ~moduleLoc:(ModulePath.getCurrent ()).loc ~path ~loc

let importedUnit unit name =
  let annotations =
    Compat.selectUnitAnnotations ~currentCmtFile:unit.cmtFilePath
      ~imports:unit.imports name
  in
  let implementation =
    annotations
    |> List.find_opt (fun (_, infos) ->
        match infos.Cmt_format.cmt_annots with
        | Implementation _ -> true
        | _ -> false)
  in
  match implementation with
  | Some (cmtFilePath, infos) -> Some (getCompilationUnit ~cmtFilePath infos)
  | None ->
    (* An interface can still expose explicit forwarding aliases when the
       implementation annotations are outside the analysis root. *)
    annotations
    |> List.find_opt (fun (_, infos) ->
        match infos.Cmt_format.cmt_annots with
        | Interface _ -> true
        | _ -> false)
    |> Option.map (fun (cmtFilePath, infos) ->
        getCompilationUnit ~cmtFilePath infos)

let rootModule unit root =
  if Ident.persistent root then
    importedUnit unit (Ident.name root)
    |> Option.map (fun provider -> (provider, provider.root))
  else
    match Ident.find_same root unit.bindings with
    | node -> Some (unit, node)
    | exception Not_found -> None

(* Resolve the alias target separately from the caller's remaining fields.
   Only alias dependencies still being followed belong on the cycle stack:
   revisiting an ordinary wrapper through another field is valid. *)
let rec modulePath ~visited unit path =
  match CompilerPath.flatten path with
  | `Contains_apply -> None
  | `Ok (root, fields) ->
    rootModule unit root
    |> Option.fold ~none:None ~some:(fun (unit, node) ->
        moduleFields ~visited unit node fields)

and moduleFields ~visited unit node fields =
  match fields with
  | [] -> Some (unit, node)
  | name :: rest ->
    let rec lookup ~aliases unit node =
      let direct =
        Hashtbl.find_opt node.modules name
        |> Option.fold ~none:None ~some:(fun child ->
            (* This field has been consumed. Alias lookups needed to select it
               are complete; only the enclosing target's dependencies remain. *)
            moduleFields ~visited unit child rest)
      in
      match direct with
      | Some _ -> direct
      | None ->
        aliasTarget ~visited:aliases unit node
        |> Option.fold ~none:None ~some:(fun (aliases, unit, target) ->
            lookup ~aliases unit target)
    in
    lookup ~aliases:visited unit node

and aliasTarget ~visited unit node =
  match node.alias with
  | None -> None
  | Some _ when List.mem node.id visited -> None
  | Some path ->
    let visited = node.id :: visited in
    modulePath ~visited unit path
    |> Option.map (fun (unit, target) -> (visited, unit, target))

let rec resolveNode ~visited unit node fields =
  let shadowed =
    match fields with
    | [name] -> (
      match Hashtbl.find_opt node.exceptions name with
      | Some OtherConstructor -> true
      | _ -> false)
    | _ -> false
  in
  let direct =
    match fields with
    | [name] ->
      Hashtbl.find_opt node.exceptions name
      |> Option.fold ~none:None ~some:(resolveException ~visited unit name)
    | name :: rest ->
      Hashtbl.find_opt node.modules name
      |> Option.fold ~none:None ~some:(fun child ->
          (* Consuming a requested field completes the preceding alias lookup. *)
          resolveNode ~visited:[] unit child rest)
    | [] -> None
  in
  match direct with
  | Some _ -> direct
  | None when shadowed -> None
  | None ->
    aliasTarget ~visited unit node
    |> Option.fold ~none:None ~some:(fun (visited, unit, target) ->
        resolveNode ~visited unit target fields)

and resolveException ~visited unit name = function
  | Declaration loc -> PosHash.find_opt unit.declarations loc.Location.loc_start
  | Included source -> resolveNode ~visited unit source [name]
  | OtherConstructor -> None

let resolvePath unit path =
  match CompilerPath.flatten path with
  | `Contains_apply -> None
  | `Ok (id, []) -> (
    (* An unqualified constructor keeps the identifier introduced by its
       declaration or include, even after another include replaces its name. *)
    match Ident.find_same id unit.exceptionBindings with
    | binding -> resolveException ~visited:[] unit (Ident.name id) binding
    | exception Not_found -> None)
  | `Ok (root, fields) ->
    rootModule unit root
    |> Option.fold ~none:None ~some:(fun (unit, node) ->
        resolveNode ~visited:[] unit node fields)

let forceDelayedItems () =
  let items = !delayedItems |> List.rev in
  delayedItems := [];
  items
  |> List.iter (fun {exceptionPath; unit; locFrom; locTo = originalLoc} ->
      match resolvePath unit exceptionPath with
      | Some locTo
        when originalLoc.loc_ghost
             || locTo.loc_start <> originalLoc.loc_start ->
        addValueReference ~addFileReference:true ~locFrom ~locTo;
        if !Config.analyzeTypes then
          TypeReferences.add locTo.loc_start locFrom.loc_start
      | _ -> ())

let markAsUsed ~(locFrom : Location.t) ~(locTo : Location.t) exceptionPath =
  if not locTo.loc_ghost then
    addValueReference ~addFileReference:true ~locFrom ~locTo;
  (* A non-ghost location can belong to an include's signature constraint.
     Retain the direct reference and also resolve the implementation declaration. *)
  !currentUnit
  |> Option.iter (fun unit ->
      delayedItems := {exceptionPath; unit; locFrom; locTo} :: !delayedItems)
