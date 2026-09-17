module CompilerPath = Path
open DeadCommon

(* A module's exported names and its lexical identity are separate: replacing
   an export must not change a binding captured by an earlier alias. *)
type moduleNode = {
  id : int;
  modules : (string, moduleNode) Hashtbl.t;
  exceptions : (string, Location.t) Hashtbl.t;
  mutable alias : CompilerPath.t option;
}

type compilationUnit = {
  cmtFilePath : string;
  imports : Misc.crcs;
  root : moduleNode;
  mutable bindings : moduleNode Ident.tbl;
  declarations : Location.t PosHash.t;
}

type item = {
  exceptionPath : CompilerPath.t;
  unit : compilationUnit;
  locFrom : Location.t;
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

let getCompilationUnit ~cmtFilePath (infos : Cmt_format.cmt_infos) =
  let key =
    ( infos.cmt_sourcefile,
      infos.cmt_builddir,
      infos.cmt_source_digest,
      match infos.cmt_annots with Interface _ -> true | _ -> false )
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
        declarations = PosHash.create 16;
      }
    in
    Hashtbl.add units key unit;
    let bind parent id node =
      unit.bindings <- Ident.add id node unit.bindings;
      Hashtbl.replace parent.modules (Ident.name id) node
    in
    let rec collectSignature node signature =
      signature
      |> List.iter (fun (item : Types.signature_item) ->
          match item with
          | Sig_module _ -> (
            match Compat.getSigModuleModtype item with
            | Some (id, moduleType, _) ->
              let child = newModule () in
              bind node id child;
              collectModuleType child moduleType
            | None -> ())
          | Sig_typext (id, extension, Text_exception, _) ->
            Hashtbl.replace node.exceptions (Ident.name id) extension.ext_loc
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
            (* Includes introduce fresh identifiers for the exported bindings.
             Point them at the concrete nodes, retaining captured old ones. *)
            incl.incl_type
            |> List.iter (fun (item : Types.signature_item) ->
                match item with
                | Sig_module _ -> (
                  match Compat.getSigModuleModtype item with
                  | Some (id, moduleType, _) ->
                    let name = Ident.name id in
                    let child =
                      match Hashtbl.find_opt included.modules name with
                      | Some child -> child
                      | None ->
                        let child = newModule () in
                        collectModuleType child moduleType;
                        child
                    in
                    (match (child.alias, included.alias) with
                    | None, Some target ->
                      child.alias <- Some (CompilerPath.Pdot (target, name))
                    | _ -> ());
                    bind node id child
                  | None -> ())
                | Sig_typext (id, extension, Text_exception, _) ->
                  let name = Ident.name id in
                  let loc =
                    match Hashtbl.find_opt included.exceptions name with
                    | Some loc -> loc
                    | None -> extension.ext_loc
                  in
                  Hashtbl.replace node.exceptions name loc
                | _ -> ())
          | Tstr_exception _ -> (
            match Compat.tstrExceptionGet item.str_desc with
            | Some (id, loc) ->
              Hashtbl.replace node.exceptions (Ident.name id) loc
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

let rec resolvePath ~visited unit path fields =
  match CompilerPath.flatten path with
  | `Contains_apply -> None
  | `Ok (root, suffix) -> (
    let fields = suffix @ fields in
    if Ident.persistent root then
      importedUnit unit (Ident.name root)
      |> Option.fold ~none:None ~some:(fun provider ->
          resolveNode ~visited provider provider.root fields)
    else
      match Ident.find_same root unit.bindings with
      | node -> resolveNode ~visited unit node fields
      | exception Not_found -> None)

and resolveNode ~visited unit node fields =
  (* Re-entering a wrapper through a different field is not a cycle. A
     repeated node with the same (or an expanding) suffix is. *)
  let rec isSuffix suffix fields =
    suffix = fields
    || match fields with _ :: rest -> isSuffix suffix rest | [] -> false
  in
  if
    List.exists
      (fun (id, suffix) -> id = node.id && isSuffix suffix fields)
      visited
  then None
  else
    let visited = (node.id, fields) :: visited in
    let direct =
      match fields with
      | [name] ->
        Hashtbl.find_opt node.exceptions name
        |> Option.fold ~none:None ~some:(fun loc ->
            PosHash.find_opt unit.declarations loc.Location.loc_start)
      | name :: rest ->
        Hashtbl.find_opt node.modules name
        |> Option.fold ~none:None ~some:(fun child ->
            resolveNode ~visited unit child rest)
      | [] -> None
    in
    match (direct, node.alias) with
    | Some _, _ -> direct
    | None, Some target -> resolvePath ~visited unit target fields
    | None, None -> None

let forceDelayedItems () =
  let items = !delayedItems |> List.rev in
  delayedItems := [];
  items
  |> List.iter (fun {exceptionPath; unit; locFrom} ->
      match resolvePath ~visited:[] unit exceptionPath [] with
      | None -> ()
      | Some locTo ->
        addValueReference ~addFileReference:true ~locFrom ~locTo;
        if !Config.analyzeTypes then
          TypeReferences.add locTo.loc_start locFrom.loc_start)

let markAsUsed ~(locFrom : Location.t) ~(locTo : Location.t) exceptionPath =
  if locTo.loc_ghost then
    !currentUnit
    |> Option.iter (fun unit ->
        delayedItems := {exceptionPath; unit; locFrom} :: !delayedItems)
  else addValueReference ~addFileReference:true ~locFrom ~locTo
