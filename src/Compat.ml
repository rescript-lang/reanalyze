#if OCAML_VERSION >= (4, 08, 0)
let getStringTag s = match s with
  | Format.String_tag(s) -> s
  | _ -> ""
#else
let getStringTag s = s
#endif

#if OCAML_VERSION >= (4, 08, 0)
let filter_map = List.filter_map
#else
(* https://github.com/ocaml/ocaml/blob/9a31c888b177f3aa603bbbe17852cbb57f047df4/stdlib/list.ml#L254-L262 passed though refmt *)
let filter_map f =
  let rec aux accu =
    function
    | [] -> List.rev accu
    | x :: l ->
      match f x with
      | None -> aux accu l
      | Some(v) -> aux (v::accu) l
       in
  aux []
#endif

let getStringValue const = match const with
#if OCAML_VERSION >= (4, 11, 0)
  | Parsetree.Pconst_string(s, _, _) -> s
#else
  | Parsetree.Pconst_string(s, _) -> s
#endif
  | _ -> assert false


let getConstString const = match const with
#if OCAML_VERSION >= (4, 11, 0)
  | Asttypes.Const_string(s, _, _) -> s
#else
  | Asttypes.Const_string(s, _) -> s
#endif
  | _ -> assert false


#if OCAML_VERSION >= (4, 11, 0)
type 'a typedtreeCase = 'a Typedtree.case
#else
type 'a typedtreeCase = Typedtree.case
#endif

#if OCAML_VERSION >= (4, 11, 0)
type 'a generalPattern = 'a Typedtree.general_pattern
#else
type 'a generalPattern = Typedtree.pattern
#endif

#if OCAML_VERSION >= (4, 13, 0)
type ('a, 'b) type_kind = ('a, 'b) Types.type_kind
#else
type ('a, 'b) type_kind = Types.type_kind
#endif

let unboxPatCstrName pat =
#if OCAML_VERSION >= (4, 11, 0)
  match pat.Typedtree.pat_desc with
  | Typedtree.Tpat_value v -> (
    match
      (v :> Typedtree.value Typedtree.pattern_desc Typedtree.pattern_data)
        .pat_desc
    with
#if OCAML_VERSION >= (4, 13, 0)
    | Tpat_construct (_, {cstr_name}, _, _) -> Some cstr_name
#else
    | Tpat_construct (_, {cstr_name}, _) -> Some cstr_name
#endif
    | _ -> None)
  | _ -> None
#else
  match pat.Typedtree.pat_desc with
    | Tpat_construct(_, {cstr_name}, _) -> Some(cstr_name)
    | _ -> None
#endif

let unboxPatCstrTxt pat = match pat with
#if OCAML_VERSION >= (4, 13, 0)
  | Typedtree.Tpat_construct ({txt}, _, _, _) -> txt
#else
  | Typedtree.Tpat_construct ({txt}, _, _) -> txt
#endif
  | _ -> assert false


#if OCAML_VERSION >= (4, 08, 0)
let setOpenCloseTag openTag closeTag =
  {
    Format.mark_open_stag = openTag;
    mark_close_stag = closeTag;
    print_open_stag = (fun _ -> ());
    print_close_stag = fun _ -> ()
  }
#else
let setOpenCloseTag openTag closeTag =
  {
    Format.mark_open_tag = openTag;
    mark_close_tag = closeTag;
    print_open_tag = (fun _ -> ());
    print_close_tag = (fun _ -> ())
  }
#endif

let pp_set_formatter_tag_functions =
#if OCAML_VERSION >= (4, 08, 0)
    Format.pp_set_formatter_stag_functions
#else
    Format.pp_set_formatter_tag_functions [@warning "-3"]
#endif

let getSigValue si = match si with
#if OCAML_VERSION >= (4, 08, 0)
  | Types.Sig_value(id, {Types.val_loc; val_kind; val_type}, _) ->
    (id, val_loc, val_kind, val_type)
#else
  | Types.Sig_value(id, {Types.val_loc; val_kind; val_type}) ->
    (id, val_loc, val_kind, val_type)
#endif
  | _ -> assert false

let getSigType si = match si with
#if OCAML_VERSION >= (4, 08, 0)
  | Types.Sig_type(id, t, _, _) ->
    (id, t)
#else
  | Types.Sig_type(id, t, _) ->
    (id, t)
#endif
  | _ -> assert false

let getTSubst td = match td with
#if OCAML_VERSION >= (4, 13, 0)
  | Types.Tsubst (t, _) -> t
#else
  | Types.Tsubst t -> t
#endif
  | _ -> assert false

let getTypeVariant (tk: ('a, 'b) type_kind) = match tk with
#if OCAML_VERSION >= (4, 13, 0)
  | Type_variant (l, _) -> l
#else
  | Type_variant l -> l
#endif
  | _ -> assert false

let getSigModuleModtype si = match si with
#if OCAML_VERSION >= (4, 08, 0)
  | Types.Sig_module(id, _, {Types.md_type=moduleType; md_loc=loc}, _, _)
  | Types.Sig_modtype(id, {Types.mtd_type=Some(moduleType); mtd_loc=loc}, _) ->
    Some((id, moduleType, loc))
#else
  | Types.Sig_module(id, {Types.md_type= moduleType; md_loc=loc}, _)
  | Types.Sig_modtype(id, {Types.mtd_type=Some(moduleType); mtd_loc=loc}) ->
    Some((id, moduleType, loc))
#endif
  | _ -> None


let getMtyFunctorModuleType  (moduleType: Types.module_type) = match moduleType with
#if OCAML_VERSION >= (4, 10, 0)
  | Mty_functor(Named(_, mtParam), mt) -> Some((Some(mtParam), mt))
  | Mty_functor(Unit, mt) -> Some((None, mt))
#else
  | Mty_functor(_, mtParam, mt) -> Some((mtParam, mt))
#endif
  | _ -> None

let getTexpMatch desc = match desc with
#if OCAML_VERSION >= (5, 3, 0)
  | Typedtree.Texp_match(e, cases, _values, partial) ->
    (e, cases, partial)
#elif OCAML_VERSION >= (4, 08, 0)
  | Typedtree.Texp_match(e, cases, partial) ->
    (e, cases, partial)
#else
  | Typedtree.Texp_match(e, casesOK, casesExn, partial) ->
    (e, casesOK @ casesExn, partial)
#endif
  | _ -> assert false

let getTexpTry desc = match desc with
#if OCAML_VERSION >= (5, 3, 0)
  | Typedtree.Texp_try(e, cases, _values) ->
    (e, cases)
#else
  | Typedtree.Texp_try(e, cases) ->
    (e, cases)
#endif
  | _ -> assert false

let texpMatchGetExceptions desc = match desc with
#if OCAML_VERSION >= (5, 3, 0)
  | Typedtree.Texp_match(_, cases, _, _) ->
    cases
    |> List.filter_map(fun ({Typedtree.c_lhs= pat}) ->
          match pat.pat_desc with
          | Tpat_exception({pat_desc}) -> Some(pat_desc)
          | _ -> None
          )
#elif OCAML_VERSION >= (4, 08, 0)
  | Typedtree.Texp_match(_, cases, _) ->
    cases
    |> List.filter_map(fun ({Typedtree.c_lhs= pat}) ->
          match pat.pat_desc with
          | Tpat_exception({pat_desc}) -> Some(pat_desc)
          | _ -> None
          )
#else
  | Typedtree.Texp_match(_, _, casesExn, _) ->
    casesExn |> List.map (fun (case: Typedtree.case) -> case.c_lhs.pat_desc)
#endif
  | _ -> assert false


let texpMatchHasExceptions desc = texpMatchGetExceptions(desc) != []



let getPayload x = 
#if OCAML_VERSION >= (4, 08, 0)
 let {Parsetree.attr_name= {txt}; attr_payload= payload} = x in
#else
 let ({Asttypes.txt}, payload) = x in
#endif
 (txt, payload)

module Ident = struct
  include Ident
#if OCAML_VERSION >= (4, 08, 0)
  let create = Ident.create_local
#endif
end

let tstrExceptionGet (x : Typedtree.structure_item_desc) = match x with
#if OCAML_VERSION >= (4, 08, 0)
  | Tstr_exception({tyexn_constructor= {ext_id}; tyexn_loc}) ->
    Some((ext_id, tyexn_loc))
#else
  | Tstr_exception({ext_id; ext_loc}) ->
    Some((ext_id, ext_loc))
#endif
  | _ -> None

#if OCAML_VERSION >= (4, 10, 0)
let moduleIdName nameOpt = match nameOpt with
  | None -> "UnnamedModule"
  | Some(name) -> name |> Ident.name
#else
let moduleIdName name = name |> Ident.name
#endif

#if OCAML_VERSION >= (4, 14, 0)
let get_desc = Types.get_desc
#else
let get_desc x = x.Types.desc
#endif

let constant_desc d =
#if OCAML_VERSION >= (5, 3, 0)
  d.Parsetree.pconst_desc
#else
  d
#endif

let tupleExpressions xs =
#if OCAML_VERSION >= (5, 4, 0)
  List.map snd xs
#else
  xs
#endif

let tupleTypes xs =
#if OCAML_VERSION >= (5, 4, 0)
  List.map snd xs
#else
  xs
#endif

let tuplePatterns xs =
#if OCAML_VERSION >= (5, 4, 0)
  List.map snd xs
#else
  xs
#endif

let applyArgToOption arg =
#if OCAML_VERSION >= (5, 4, 0)
  match arg with Typedtree.Arg e -> Some e | Typedtree.Omitted () -> None
#else
  arg
#endif

let applyArgOfExpression e =
#if OCAML_VERSION >= (5, 4, 0)
  Typedtree.Arg e
#else
  Some e
#endif

(* Index of the .cmt/.cmti files under analysis, keyed by compilation unit
   name. Populated before processing so declaration dependencies and identifier
   occurrences pointing at other units (e.g. a functor result constrained by a
   module type defined in another file) can be resolved regardless of
   processing order. *)
let cmtFilesByUnit : (string, string list) Hashtbl.t = Hashtbl.create 256

let unitNameOfCmtFile path =
  path |> Filename.basename |> Filename.remove_extension
  |> String.capitalize_ascii

let registerCmtFile path =
  let unit = unitNameOfCmtFile path in
  let existing =
    match Hashtbl.find_opt cmtFilesByUnit unit with
    | Some paths -> paths
    | None -> []
  in
  if not (List.mem path existing) then
    Hashtbl.replace cmtFilesByUnit unit (path :: existing)

#if OCAML_VERSION >= (5, 3, 0)
(* Per compilation unit: the implementation shape (from the .cmt) and the
   uid -> declaration table (merged from .cmt and .cmti). Loaded on demand. *)
type unitInfo = {
  shape : Shape.t option;
  uidToDecl : Typedtree.item_declaration Shape.Uid.Tbl.t;
}

(* Keyed by the list of files a unit is loaded from, so that same-named units
   in different build targets (e.g. two unwrapped libraries each defining
   [Config]) do not share an entry. *)
let unitInfoCache : (string list * string option, unitInfo) Hashtbl.t =
  Hashtbl.create 64

let candidateFilesForUnit ~currentCmtFile comp_unit =
  let dir = Filename.dirname currentCmtFile in
  let indexed =
    match Hashtbl.find_opt cmtFilesByUnit comp_unit with
    | Some paths -> paths
    | None -> []
  in
  (* Fall back to sibling files, for callers that did not register. *)
  let siblings =
    [".cmt"; ".cmti"]
    |> List.concat_map (fun ext ->
           [
             Filename.concat dir (comp_unit ^ ext);
             Filename.concat dir (String.uncapitalize_ascii comp_unit ^ ext);
           ])
  in
  let candidates =
    (indexed @ siblings) |> List.filter Sys.file_exists |> List.sort_uniq compare
  in
  (* Prefer the unit built alongside the current file when the same unit name
     exists in several build targets. *)
  match candidates |> List.filter (fun p -> Filename.dirname p = dir) with
  | [] -> candidates
  | sameDir -> sameDir

(* [imports] are the consumer's recorded imports: when the same unit name
   exists in several build directories, the candidate whose interface digest
   matches the one the consumer was compiled against is the actual
   dependency. *)
let loadUnitInfo ~currentCmtFile ~(imports : Misc.crcs) comp_unit =
  let files = candidateFilesForUnit ~currentCmtFile comp_unit in
  let digest =
    match List.assoc_opt comp_unit imports with
    | Some (Some digest) -> Some digest
    | _ -> None
  in
  (* The digest takes part in the key: two consumers compiled against
     different same-named units must not share an entry. *)
  let cacheKey = (files, Option.map Digest.to_hex digest) in
  match Hashtbl.find_opt unitInfoCache cacheKey with
  | Some info -> Some info
  | None -> (
    match files with
    | [] -> None
    | _ ->
      let read path =
        try Some (path, Cmt_format.read_cmt path) with _ -> None
      in
      let loaded = files |> List.filter_map read in
      let dirs =
        loaded |> List.map (fun (p, _) -> Filename.dirname p)
        |> List.sort_uniq compare
      in
      let loaded =
        match (dirs, digest) with
        | _ :: _ :: _, Some digest -> (
          match
            loaded
            |> List.filter (fun (_, (cmt_infos : Cmt_format.cmt_infos)) ->
                   cmt_infos.cmt_interface_digest = Some digest)
          with
          | [] -> loaded
          | matching -> matching)
        | _ -> loaded
      in
      let uidToDecl = Shape.Uid.Tbl.create 64 in
      let shape = ref None in
      loaded
      |> List.iter (fun (_, (cmt_infos : Cmt_format.cmt_infos)) ->
             Shape.Uid.Tbl.iter
               (fun uid decl ->
                 if not (Shape.Uid.Tbl.mem uidToDecl uid) then
                   Shape.Uid.Tbl.replace uidToDecl uid decl)
               cmt_infos.cmt_uid_to_decl;
             match (!shape, cmt_infos.cmt_impl_shape) with
             | None, Some _ -> shape := cmt_infos.cmt_impl_shape
             | _ -> ());
      let info = {shape = !shape; uidToDecl} in
      Hashtbl.replace unitInfoCache cacheKey info;
      Some info)

let locOfItemDeclaration = function
  | Typedtree.Value {val_loc; _} -> Some val_loc
  | Typedtree.Value_binding {vb_pat = {pat_loc; _}; _} -> Some pat_loc
  | _ -> None

let declOfUid ~currentCmtFile ~imports
    ~(local : Typedtree.item_declaration Shape.Uid.Tbl.t) uid =
  match Shape.Uid.Tbl.find_opt local uid with
  | Some decl -> Some decl
  | None -> (
    match uid with
    | Shape.Uid.Item {comp_unit; _} -> (
      match loadUnitInfo ~currentCmtFile ~imports comp_unit with
      | Some {uidToDecl} -> Shape.Uid.Tbl.find_opt uidToDecl uid
      | None -> None)
    | _ -> None)

let locOfUid ~currentCmtFile ~imports ~local uid =
  match declOfUid ~currentCmtFile ~imports ~local uid with
  | Some decl -> locOfItemDeclaration decl
  | None -> None

let moduleBindingOfUid ~currentCmtFile ~imports ~local uid =
  match declOfUid ~currentCmtFile ~imports ~local uid with
  | Some (Typedtree.Module_binding {mb_name = {loc}; mb_expr}) ->
    Some (loc, mb_expr)
  | _ -> None

let moduleBindingLocOfUid ~currentCmtFile ~imports ~local uid =
  match moduleBindingOfUid ~currentCmtFile ~imports ~local uid with
  | Some (loc, _) -> Some loc
  | None -> None

let moduleTypeOfUid ~currentCmtFile ~imports ~local uid =
  match declOfUid ~currentCmtFile ~imports ~local uid with
  | Some (Typedtree.Module_type {mtd_type = Some {mty_type}}) -> Some mty_type
  | _ -> None
#endif

let extractValueDependencies ~cmtFilePath (cmt_infos : Cmt_format.cmt_infos) =
#if OCAML_VERSION >= (5, 3, 0)
  let local = Shape.Uid.Tbl.create 1024 in
  Shape.Uid.Tbl.iter (Shape.Uid.Tbl.replace local) cmt_infos.cmt_uid_to_decl;
  (let cmti = (cmtFilePath |> Filename.remove_extension) ^ ".cmti" in
   if Sys.file_exists cmti then
     try
       let cmti_infos = Cmt_format.read_cmt cmti in
       Shape.Uid.Tbl.iter
         (fun uid decl ->
           if not (Shape.Uid.Tbl.mem local uid) then
             Shape.Uid.Tbl.replace local uid decl)
         cmti_infos.cmt_uid_to_decl
     with _ -> ());
  let loc_of_uid =
    locOfUid ~currentCmtFile:cmtFilePath ~imports:cmt_infos.cmt_imports ~local
  in
  cmt_infos.cmt_declaration_dependencies
  |> filter_map (fun (_, uid_def, uid_decl) ->
         match (loc_of_uid uid_def, loc_of_uid uid_decl) with
         | Some def_loc, Some decl_loc -> Some (def_loc, decl_loc)
         | _ -> None)
#else
  let _ = cmtFilePath in
  cmt_infos.cmt_value_dependencies
  |> List.map (fun (valueTo, valueFrom) ->
         (valueTo.Types.val_loc, valueFrom.Types.val_loc))
#endif

(* Resolution of identifier occurrences to the implementation they denote.

   An occurrence such as [Inst.H.find_opt], where [H] is an instance of a
   functor constrained by a named module type, has a [val_loc] pointing at the
   module type item. Reducing the occurrence's shape (through the shapes of the
   other compilation units) yields the implementation instead, so references
   land on the right definition rather than on the shared module type item.

   Occurrences are keyed by their location and last name component, so that
   distinct identifiers a ppx may emit at the same position do not collide. *)
type moduleShape =
#if OCAML_VERSION >= (5, 3, 0)
  Shape.t
#else
  unit
#endif

type identResolutions = {
  valueImpl : Location.t -> string -> Location.t option;
      (** occurrence location, last name -> implementation location *)
  moduleShape : Location.t -> string -> moduleShape option;
      (** occurrence location, last name -> shape of the module *)
  projValue : moduleShape -> string -> Location.t option;
      (** implementation of a value item of a module shape *)
  projModule : moduleShape -> string -> moduleShape option;
      (** shape of a module item of a module shape *)
  moduleDefLoc : Location.t -> string -> Location.t option;
      (** occurrence location, last name -> location of the module binding's
          name, for a module (e.g. a functor) defined with [module X = ...] *)
  moduleTypeOf : Location.t -> string -> Types.module_type option;
      (** occurrence location, last name -> the module type a
          [module type X = ...] declaration denotes *)
  moduleDefinition :
    Location.t -> string -> (Location.t * Typedtree.module_expr) option;
      (** occurrence location, last name -> the module binding's name location
          and expression *)
}

let emptyIdentResolutions =
  {
    valueImpl = (fun _ _ -> None);
    moduleShape = (fun _ _ -> None);
    projValue = (fun _ _ -> None);
    projModule = (fun _ _ -> None);
    moduleDefLoc = (fun _ _ -> None);
    moduleTypeOf = (fun _ _ -> None);
    moduleDefinition = (fun _ _ -> None);
  }

#if OCAML_VERSION >= (5, 3, 0)
(* Find, inside the implementation shape of the current unit, the shape of the
   item defined with [uid]. Used for modules defined locally, whose occurrences
   the compiler resolves to a uid rather than leaving a shape. *)
let rec findShapeByUid (shape : Shape.t) uid : Shape.t option =
  if shape.uid = Some uid then Some shape
  else
    match shape.desc with
    | Struct items ->
      Shape.Item.Map.fold
        (fun _item itemShape acc ->
          match acc with
          | Some _ -> acc
          | None -> findShapeByUid itemShape uid)
        items None
    | Alias s -> findShapeByUid s uid
    | _ -> None
#endif

(* Whether occurrences can be resolved through shapes at all. Without it,
   references through a functor parameter can only be credited conservatively,
   to every implementation of the module type item. *)
let shapeResolutionAvailable =
#if OCAML_VERSION >= (5, 3, 0)
  true
#else
  false
#endif

let resolveIdentOccurrences ~cmtFilePath (cmt_infos : Cmt_format.cmt_infos) :
    identResolutions =
#if OCAML_VERSION >= (5, 3, 0)
  let module Reduce = Shape_reduce.Make (struct
    let fuel = 10

    let read_unit_shape ~unit_name =
      match
        loadUnitInfo ~currentCmtFile:cmtFilePath ~imports:cmt_infos.cmt_imports
          unit_name
      with
      | Some {shape} -> shape
      | None -> None
  end) in
  let local = cmt_infos.cmt_uid_to_decl in
  let imports = cmt_infos.cmt_imports in
  let locOfUid = locOfUid ~currentCmtFile:cmtFilePath ~imports ~local in
  let rec uidOfResult (result : Shape_reduce.result) =
    match result with
    | Resolved uid -> Some uid
    | Resolved_alias (_, result) -> uidOfResult result
    | _ -> None
  in
  let key (loc : Location.t) name = (loc.loc_start, loc.loc_end, name) in
  let values = Hashtbl.create 64 in
  let modules = Hashtbl.create 16 in
  let moduleUids = Hashtbl.create 16 in
  cmt_infos.cmt_ident_occurrences
  |> List.iter (fun ((lid : Longident.t Location.loc), result) ->
         if not lid.loc.loc_ghost then
           let name = Longident.last lid.txt in
           let k = key lid.loc name in
           match result with
           | Shape_reduce.Unresolved shape ->
             (* Definition in another unit: reduce lazily, as a value and as a
                module, depending on how the occurrence is used. *)
             let uid =
               lazy (Reduce.reduce_for_uid Env.empty shape |> uidOfResult)
             in
             Hashtbl.replace values k (lazy (
               match Lazy.force uid with
               | Some uid -> locOfUid uid
               | None -> None));
             Hashtbl.replace modules k (Some shape);
             Hashtbl.replace moduleUids k uid
           | _ -> (
             match uidOfResult result with
             | Some uid ->
               Hashtbl.replace values k (lazy (locOfUid uid));
               Hashtbl.replace modules k
                 (match cmt_infos.cmt_impl_shape with
                 | Some impl -> findShapeByUid impl uid
                 | None -> None);
               Hashtbl.replace moduleUids k (lazy (Some uid))
             | None -> ()));
  let nonGhost (loc : Location.t option) =
    match loc with Some l when not l.loc_ghost -> loc | _ -> None
  in
  {
    valueImpl =
      (fun loc name ->
        match Hashtbl.find_opt values (key loc name) with
        | Some l -> Lazy.force l |> nonGhost
        | None -> None);
    moduleShape =
      (fun loc name ->
        match Hashtbl.find_opt modules (key loc name) with
        | Some s -> s
        | None -> None);
    projValue =
      (fun shape name ->
        let item = Shape.proj shape (Shape.Item.make name Value) in
        match Reduce.reduce_for_uid Env.empty item |> uidOfResult with
        | Some uid -> locOfUid uid |> nonGhost
        | None -> None);
    projModule =
      (fun shape name ->
        Some (Shape.proj shape (Shape.Item.make name Module)));
    moduleDefLoc =
      (fun loc name ->
        match Hashtbl.find_opt moduleUids (key loc name) with
        | Some uid -> (
          match Lazy.force uid with
          | Some uid ->
            moduleBindingLocOfUid ~currentCmtFile:cmtFilePath ~imports ~local
              uid
            |> nonGhost
          | None -> None)
        | None -> None);
    moduleTypeOf =
      (fun loc name ->
        match Hashtbl.find_opt moduleUids (key loc name) with
        | Some uid -> (
          match Lazy.force uid with
          | Some uid ->
            moduleTypeOfUid ~currentCmtFile:cmtFilePath ~imports ~local uid
          | None -> None)
        | None -> None);
    moduleDefinition =
      (fun loc name ->
        match Hashtbl.find_opt moduleUids (key loc name) with
        | Some uid -> (
          match Lazy.force uid with
          | Some uid -> (
            match
              moduleBindingOfUid ~currentCmtFile:cmtFilePath ~imports ~local uid
            with
            | Some (loc, _) when loc.loc_ghost -> None
            | def -> def)
          | None -> None)
        | None -> None);
  }
#else
  let _ = (cmtFilePath, cmt_infos) in
  emptyIdentResolutions
#endif
