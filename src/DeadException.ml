module CompilerPath = Path

open DeadCommon
open Common

type item = {exceptionPath : Path.t; locFrom : Location.t}

let delayedItems = ref []
let declarations = Hashtbl.create 1
let compilationUnit = ref ""
let moduleAliases = Hashtbl.create 16

(* A wrapper exposes compilation units through module aliases, for example
   [Dune__exe.Location = Dune__exe__Location]. Read these aliases even when
   the wrapper's generated source is unavailable. Never infer them by
   dropping a namespace or by recognizing a compiler's naming convention. *)
let registerCompilationUnit (infos : Cmt_format.cmt_infos) =
  compilationUnit := infos.cmt_modname;
  let unitName = Name.create ~isInterface:false infos.cmt_modname in
  let signature =
    match infos.cmt_annots with
    | Implementation structure -> structure.str_type
    | Interface signature -> signature.sig_type
    | _ -> []
  in
  signature
  |> List.iter (fun (item : Types.signature_item) ->
         match item with
         | Sig_module _ -> (
           match Compat.getSigModuleModtype item with
           | Some (id, Mty_alias target, _) -> (
             match CompilerPath.flatten target with
             | `Ok (root, _) when Ident.persistent root ->
               Hashtbl.replace moduleAliases
                 [Name.create (Ident.name id); unitName]
                 (target |> Path.fromPathT |> Path.moduleToImplementation)
             | _ -> ())
           | _ -> ())
         | _ -> ())

let add ~path ~loc ~(strLoc : Location.t) name =
  let exceptionPath =
    match List.rev (name :: path) with
    | _ :: rest ->
      List.rev (Name.create ~isInterface:false !compilationUnit :: rest)
    | [] -> []
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
