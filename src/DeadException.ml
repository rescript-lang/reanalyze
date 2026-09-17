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
           | Some (id, Mty_alias (Pident target), _)
             when Ident.persistent target ->
             Hashtbl.replace moduleAliases
               [Name.create (Ident.name id); unitName]
               [Name.create ~isInterface:false (Ident.name target)]
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

let rec resolveModuleAliases path =
  match Hashtbl.find_opt moduleAliases path with
  | Some target -> target
  | None -> (
    match path with
    | name :: rest -> name :: resolveModuleAliases rest
    | [] -> [])

let findDeclaration exceptionPath =
  match exceptionPath |> Path.moduleToImplementation with
  | name :: modulePath ->
    Hashtbl.find_opt declarations (name :: resolveModuleAliases modulePath)
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
