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

(* Whether a signature item occupies a runtime slot, as the positions of a
   [Tcoerce_structure] count them: values (not primitives), extension
   constructors, present modules and classes. *)
let isRuntimeField (si : Types.signature_item) =
  match si with
  | Types.Sig_value (_, {val_kind = Val_prim _}, _) -> false
  | Types.Sig_value _ -> true
  | Types.Sig_typext _ -> true
  | Types.Sig_module (_, Mp_present, _, _, _) -> true
  | Types.Sig_module (_, Mp_absent, _, _, _) -> false
  | Types.Sig_class _ -> true
  | _ -> false

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
  cmtPath : string;  (** the .cmt (or, failing that, the first file) loaded *)
  unitImports : Misc.crcs;
  occurrences : (Longident.t Location.loc * Shape_reduce.result) list;
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
      (* Candidates still spanning several build directories (same name and
         same interface) cannot be told apart: resolve nothing rather than
         redirect into the wrong target. *)
      let loaded =
        match
          loaded |> List.map (fun (p, _) -> Filename.dirname p)
          |> List.sort_uniq compare
        with
        | _ :: _ :: _ -> []
        | _ -> loaded
      in
      let uidToDecl = Shape.Uid.Tbl.create 64 in
      let shape = ref None in
      let implementation = ref None in
      loaded
      |> List.iter (fun (path, (cmt_infos : Cmt_format.cmt_infos)) ->
             Shape.Uid.Tbl.iter
               (fun uid decl ->
                 if not (Shape.Uid.Tbl.mem uidToDecl uid) then
                   Shape.Uid.Tbl.replace uidToDecl uid decl)
               cmt_infos.cmt_uid_to_decl;
             match (!shape, cmt_infos.cmt_impl_shape) with
             | None, Some _ ->
               shape := cmt_infos.cmt_impl_shape;
               implementation := Some (path, cmt_infos)
             | _ -> ());
      let cmtPath, unitImports, occurrences =
        match (!implementation, loaded) with
        | Some (path, cmt_infos), _ | None, (path, cmt_infos) :: _ ->
          (path, cmt_infos.cmt_imports, cmt_infos.cmt_ident_occurrences)
        | None, [] -> ("", [], [])
      in
      let info = {shape = !shape; uidToDecl; cmtPath; unitImports; occurrences} in
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

(* Bindings already chased when resolving a functor head, to break cycles. *)
type headVisited =
#if OCAML_VERSION >= (5, 3, 0)
  Shape.Uid.t list
#else
  unit
#endif

let noHeadVisited : headVisited =
#if OCAML_VERSION >= (5, 3, 0)
  []
#else
  ()
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
  headKey :
    headVisited -> Typedtree.module_expr -> (Location.t * int) option;
      (** visited bindings (start with [noHeadVisited]), module expression ->
          the binding name location of the functor it stands for, through
          aliases and partial applications (possibly bound in other units,
          resolved with those units' own occurrence data), and the number of
          arguments those partial applications consumed; inline functors are
          keyed by their own location *)
  expandModuleType : Types.module_type -> Types.module_type;
      (** follow module type aliases ([module type S = Base]) until a signature
          or an unresolvable name is reached *)
}

let emptyIdentResolutions =
  {
    valueImpl = (fun _ _ -> None);
    moduleShape = (fun _ _ -> None);
    projValue = (fun _ _ -> None);
    projModule = (fun _ _ -> None);
    moduleDefLoc = (fun _ _ -> None);
    moduleTypeOf = (fun _ _ -> None);
    headKey = (fun _ _ -> None);
    expandModuleType = (fun mt -> mt);
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
    | Abs (_, body) -> findShapeByUid body uid
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

#if OCAML_VERSION >= (5, 3, 0)
(* Resolvers of other units, by .cmt path, for chasing definitions bound
   there (aliases and partial applications of functors). *)
let resolverCache : (string, identResolutions) Hashtbl.t = Hashtbl.create 16

let rec makeResolver ~cmtFilePath
    ~(local : Typedtree.item_declaration Shape.Uid.Tbl.t)
    ~(imports : Misc.crcs) ~(implShape : Shape.t option)
    ~(occurrences : (Longident.t Location.loc * Shape_reduce.result) list) :
    identResolutions =
  let module Reduce = Shape_reduce.Make (struct
    (* Bounds the reduction of recursive shapes; long alias and projection
       chains must not be cut short by it. *)
    let fuel = 100

    let read_unit_shape ~unit_name =
      match loadUnitInfo ~currentCmtFile:cmtFilePath ~imports unit_name with
      | Some {shape} -> shape
      | None -> None
  end) in
  let thisUnit = unitNameOfCmtFile cmtFilePath in
  let compUnitShape name =
    {Shape.uid = None; desc = Comp_unit name; approximated = false}
  in
  (* The uid of a declaration of this unit, by identifier. *)
  let localUid (matches : Typedtree.item_declaration -> bool) =
    Shape.Uid.Tbl.fold
      (fun uid decl acc ->
        match acc with
        | Some _ -> acc
        | None -> if matches decl then Some uid else None)
      local None
  in
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
  (* Occurrences sharing a key but spelled differently (distinct identifiers
     a ppx emitted at one position, e.g. [A.f] and [B.f]) cannot be told apart
     from the typed tree, whose paths differ from the written identifiers under
     [open] and aliases: such keys are left unresolved, conservatively. *)
  (* [Longident.last] and [flatten] are fatal on [Lapply] ([F(X).t]): such
     occurrences are not values or modules of interest here. *)
  let lidText (lid : Longident.t) =
    match Longident.flatten lid with
    | components -> Some (String.concat "." components)
    | exception Misc.Fatal_error -> None
  in
  (* Two occurrences with one key are the same identifier only if they are
     spelled the same and the compiler resolved them the same way (the same
     spelling can resolve differently under distinct local opens). *)
  let identity (lid : Longident.t) (result : Shape_reduce.result) =
    match lidText lid with
    | None -> None
    | Some text ->
      let resolution =
        match result with
        | Unresolved shape -> Format.asprintf "%a" Shape.print shape
        | result -> Format.asprintf "%a" Shape_reduce.print_result result
      in
      Some (text ^ " " ^ resolution)
  in
  let spelled = Hashtbl.create 64 in
  let ambiguous = Hashtbl.create 4 in
  occurrences
  |> List.iter (fun ((lid : Longident.t Location.loc), result) ->
         if not lid.loc.loc_ghost then
           match identity lid.txt result with
           | None -> ()
           | Some id -> (
             let k = key lid.loc (Longident.last lid.txt) in
             match Hashtbl.find_opt spelled k with
             | Some other when other <> id -> Hashtbl.replace ambiguous k ()
             | _ -> Hashtbl.replace spelled k id));
  occurrences
  |> List.iter (fun ((lid : Longident.t Location.loc), result) ->
         if (not lid.loc.loc_ghost) && lidText lid.txt <> None then
           let name = Longident.last lid.txt in
           let k = key lid.loc name in
           if Hashtbl.mem ambiguous k then ()
           else
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
                 (match implShape with
                 | Some impl -> findShapeByUid impl uid
                 | None -> None);
               Hashtbl.replace moduleUids k (lazy (Some uid))
             | None -> ()));
  let nonGhost (loc : Location.t option) =
    match loc with Some l when not l.loc_ghost -> loc | _ -> None
  in
  let rec self : identResolutions = {
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
    headKey =
      (let bindingOfUid =
         moduleBindingOfUid ~currentCmtFile:cmtFilePath ~imports ~local
       in
       let rec unwrap (e : Typedtree.module_expr) =
         match e.mod_desc with
         | Tmod_constraint (inner, _, _, _) -> unwrap inner
         | _ -> e
       in
       (* The resolver of the unit defining [uid]: this one, or that unit's
          own, built from its occurrence data. *)
       let resolverOfUid (uid : Shape.Uid.t) =
         match uid with
         | Shape.Uid.Item {comp_unit; _} when comp_unit = thisUnit -> Some self
         | Shape.Uid.Item {comp_unit; _} ->
           resolverForUnit ~currentCmtFile:cmtFilePath ~imports comp_unit
         | _ -> None
       in
       (* The key of a binding found for a module expression: a functor is
          keyed by the binding; an alias or a partial application is chased
          with the resolver of the unit binding it. *)
       let keyOfBinding visited (loc : Location.t)
           (definition : Typedtree.module_expr) resolver =
         if loc.loc_ghost then None
         else
           match (unwrap definition).mod_desc with
           | Tmod_apply _ | Tmod_ident _ -> (
             match resolver with
             | Some (resolver : identResolutions) -> (
               match resolver.headKey visited definition with
               | Some head -> Some head
               | None -> Some (loc, 0))
             | None -> Some (loc, 0))
           | _ -> Some (loc, 0)
       in
       (* The binding a module path denotes, structurally: through units,
          local bindings, and the bodies of applied functors, as in
          [Outer (A).Inner]. Returns the binding, the resolver of its unit,
          and the number of functor layers the path applied. *)
       let rec bindingOfPath (path : Path.t) :
           (Location.t * Typedtree.module_expr * identResolutions option * int)
           option =
         match path with
         | Pident id when Ident.global id -> None
         | Pident id -> (
           let uid =
             localUid (function
               | Typedtree.Module_binding {mb_id = Some mbId} ->
                 Ident.same mbId id
               | _ -> false)
           in
           match uid with
           | Some uid -> (
             match bindingOfUid uid with
             | Some (loc, definition) -> Some (loc, definition, Some self, 0)
             | None -> None)
           | None -> None)
         | Pdot (Pident unit, name) when Ident.global unit -> (
           let shape =
             Shape.proj (compUnitShape (Ident.name unit))
               (Shape.Item.make name Module)
           in
           match Reduce.reduce_for_uid Env.empty shape |> uidOfResult with
           | Some uid -> (
             match bindingOfUid uid with
             | Some (loc, definition) ->
               Some (loc, definition, resolverOfUid uid, 0)
             | None -> None)
           | None -> None)
         | Pdot (parent, name) -> (
           match bindingOfPath parent with
           | Some (_, definition, resolver, applied) -> (
             (* Peel the applied functor layers, then find the member, the
                last binding of that name (also through [include]s). *)
             let rec memberIn (e : Typedtree.module_expr) applied =
               match e.mod_desc with
               | Tmod_constraint (inner, _, _, _) -> memberIn inner applied
               | Tmod_functor (_, inner) when applied > 0 ->
                 memberIn inner (applied - 1)
               | Tmod_apply (functorExpr, _, _) ->
                 memberIn functorExpr (applied + 1)
               | Tmod_ident (p, _) when applied = 0 -> (
                 match bindingOfPath (Pdot (p, name)) with
                 | Some (loc, expr, _, 0) -> Some (loc, expr)
                 | _ -> None)
               | Tmod_structure structure when applied = 0 ->
                 structure.str_items
                 |> List.fold_left
                      (fun acc (item : Typedtree.structure_item) ->
                        match item.str_desc with
                        | Tstr_module ({mb_name = {txt = Some n}} as mb)
                          when n = name ->
                          Some (mb.mb_name.loc, mb.mb_expr)
                        | Tstr_recmodule mbs -> (
                          match
                            mbs
                            |> List.find_opt
                                 (fun (mb : Typedtree.module_binding) ->
                                   mb.mb_name.txt = Some name)
                          with
                          | Some mb -> Some (mb.mb_name.loc, mb.mb_expr)
                          | None -> acc)
                        | Tstr_include {incl_mod} -> (
                          match memberIn incl_mod 0 with
                          | Some member -> Some member
                          | None -> acc)
                        | _ -> acc)
                      None
               | _ -> None
             in
             match memberIn definition applied with
             | Some (loc, expr) -> Some (loc, expr, resolver, 0)
             | None -> None)
           | None -> None)
         | Papply (functorPath, _) -> (
           match bindingOfPath functorPath with
           | Some (loc, definition, resolver, applied) ->
             Some (loc, definition, resolver, applied + 1)
           | None -> None)
         | _ -> None
       in
       let rec headKey (visited : headVisited) (e : Typedtree.module_expr) =
         match e.mod_desc with
         | Tmod_apply (functorExpr, _, _) -> (
           match headKey visited functorExpr with
           | Some (loc, consumed) -> Some (loc, consumed + 1)
           | None -> None)
         | Tmod_constraint (inner, _, _, _) -> headKey visited inner
         | Tmod_functor _ -> Some (e.mod_loc, 0)
         | Tmod_ident (path, lid) -> (
           let byOccurrence =
             match Longident.last lid.txt with
             | exception Misc.Fatal_error -> None
             | name -> (
               match Hashtbl.find_opt moduleUids (key lid.loc name) with
               | Some uid -> (
                 match Lazy.force uid with
                 | Some uid when not (List.mem uid visited) -> (
                   match bindingOfUid uid with
                   | Some (loc, definition) ->
                     keyOfBinding (uid :: visited) loc definition
                       (resolverOfUid uid)
                   | None -> None)
                 | _ -> None)
               | None -> None)
           in
           match byOccurrence with
           | Some head -> Some head
           | None -> (
             (* No usable occurrence (e.g. [Outer (A).Inner]): structurally. *)
             match bindingOfPath path with
             | Some (loc, definition, resolver, 0) ->
               keyOfBinding visited loc definition resolver
             | _ -> None))
         | _ -> None
       in
       headKey);
    expandModuleType =
      (       (* Shape of a module path rooted at a compilation unit or at a module
          of the current unit. *)
       let rec moduleShapeOfPath (path : Path.t) =
         match path with
         | Pident id when Ident.global id -> Some (compUnitShape (Ident.name id))
         | Pident id -> (
           let uid =
             localUid (function
               | Typedtree.Module_binding {mb_id = Some mbId} ->
                 Ident.same mbId id
               | _ -> false)
           in
           match (uid, implShape) with
           | Some uid, Some impl -> findShapeByUid impl uid
           | _ -> None)
         | Pdot (p, name) -> (
           match moduleShapeOfPath p with
           | Some shape -> Some (Shape.proj shape (Shape.Item.make name Module))
           | None -> None)
         | _ -> None
       in
       let moduleTypeOfUid = moduleTypeOfUid ~currentCmtFile:cmtFilePath ~imports ~local in
       let moduleTypeOfPath (path : Path.t) =
         match path with
         | Pdot (p, name) -> (
           match moduleShapeOfPath p with
           | Some shape -> (
             let item = Shape.proj shape (Shape.Item.make name Module_type) in
             match Reduce.reduce_for_uid Env.empty item |> uidOfResult with
             | Some uid -> moduleTypeOfUid uid
             | None -> None)
           | None -> None)
         | Pident id ->
           (* A module type of the current unit, by identifier identity (the
              same name may be declared in several scopes). *)
           Shape.Uid.Tbl.fold
             (fun _uid decl acc ->
               match (acc, decl) with
               | None, Typedtree.Module_type {mtd_id; mtd_type = Some {mty_type}}
                 when Ident.same mtd_id id ->
                 Some mty_type
               | _ -> acc)
             local None
         | _ -> None
       in
       (* The declared type of the module a path denotes: a strengthened
          signature turns submodules into aliases ([module N = Arg.N]),
          which expose no items. *)
       let moduleTypeOfModulePath (path : Path.t) =
         match moduleShapeOfPath path with
         | Some shape -> (
           match Reduce.reduce_for_uid Env.empty shape |> uidOfResult with
           | Some uid -> (
             match declOfUid ~currentCmtFile:cmtFilePath ~imports ~local uid with
             | Some (Typedtree.Module_binding {mb_expr}) -> Some mb_expr.mod_type
             | Some (Typedtree.Module {md_type}) -> Some md_type.mty_type
             | _ -> None)
           | None -> None)
         | None -> None
       in
       (* Aliases are followed until a signature is reached; the visited
          paths break cycles. *)
       let rec expand visited (moduleType : Types.module_type) =
         match moduleType with
         | Mty_ident path when not (List.exists (Path.same path) visited) -> (
           match moduleTypeOfPath path with
           | Some expanded -> expand (path :: visited) expanded
           | None -> moduleType)
         | Mty_alias path when not (List.exists (Path.same path) visited) -> (
           match moduleTypeOfModulePath path with
           | Some expanded -> expand (path :: visited) expanded
           | None -> moduleType)
         | _ -> moduleType
       in
       expand []);
  } in
  self

and resolverForUnit ~currentCmtFile ~imports comp_unit =
  match loadUnitInfo ~currentCmtFile ~imports comp_unit with
  | Some info when info.cmtPath <> "" -> (
    match Hashtbl.find_opt resolverCache info.cmtPath with
    | Some resolver -> Some resolver
    | None ->
      let resolver =
        makeResolver ~cmtFilePath:info.cmtPath ~local:info.uidToDecl
          ~imports:info.unitImports ~implShape:info.shape
          ~occurrences:info.occurrences
      in
      Hashtbl.replace resolverCache info.cmtPath resolver;
      Some resolver)
  | _ -> None
#endif

let resolveIdentOccurrences ~cmtFilePath (cmt_infos : Cmt_format.cmt_infos) :
    identResolutions =
#if OCAML_VERSION >= (5, 3, 0)
  makeResolver ~cmtFilePath ~local:cmt_infos.cmt_uid_to_decl
    ~imports:cmt_infos.cmt_imports ~implShape:cmt_infos.cmt_impl_shape
    ~occurrences:cmt_infos.cmt_ident_occurrences
#else
  let _ = (cmtFilePath, cmt_infos) in
  emptyIdentResolutions
#endif
