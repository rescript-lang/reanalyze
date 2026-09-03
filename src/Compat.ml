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

let unitInfoCache : (string, unitInfo) Hashtbl.t = Hashtbl.create 64

let candidateFilesForUnit ~currentCmtFile comp_unit =
  let indexed =
    match Hashtbl.find_opt cmtFilesByUnit comp_unit with
    | Some paths -> paths
    | None -> []
  in
  (* Fall back to sibling files, for callers that did not register. *)
  let dir = Filename.dirname currentCmtFile in
  let siblings =
    [".cmt"; ".cmti"]
    |> List.concat_map (fun ext ->
           [
             Filename.concat dir (comp_unit ^ ext);
             Filename.concat dir (String.uncapitalize_ascii comp_unit ^ ext);
           ])
  in
  (indexed @ siblings) |> List.filter Sys.file_exists |> List.sort_uniq compare

let loadUnitInfo ~currentCmtFile comp_unit =
  match Hashtbl.find_opt unitInfoCache comp_unit with
  | Some info -> Some info
  | None -> (
    let files = candidateFilesForUnit ~currentCmtFile comp_unit in
    match files with
    | [] -> None
    | _ ->
      let uidToDecl = Shape.Uid.Tbl.create 64 in
      let shape = ref None in
      files
      |> List.iter (fun path ->
             try
               let cmt_infos = Cmt_format.read_cmt path in
               Shape.Uid.Tbl.iter
                 (fun uid decl ->
                   if not (Shape.Uid.Tbl.mem uidToDecl uid) then
                     Shape.Uid.Tbl.replace uidToDecl uid decl)
                 cmt_infos.cmt_uid_to_decl;
               match (!shape, cmt_infos.cmt_impl_shape) with
               | None, Some _ -> shape := cmt_infos.cmt_impl_shape
               | _ -> ()
             with _ -> ());
      let info = {shape = !shape; uidToDecl} in
      Hashtbl.replace unitInfoCache comp_unit info;
      Some info)

let locOfItemDeclaration = function
  | Typedtree.Value {val_loc; _} -> Some val_loc
  | Typedtree.Value_binding {vb_pat = {pat_loc; _}; _} -> Some pat_loc
  | _ -> None

let locOfUid ~currentCmtFile ~(local : Typedtree.item_declaration Shape.Uid.Tbl.t)
    uid =
  match Shape.Uid.Tbl.find_opt local uid with
  | Some decl -> locOfItemDeclaration decl
  | None -> (
    match uid with
    | Shape.Uid.Item {comp_unit; _} -> (
      match loadUnitInfo ~currentCmtFile comp_unit with
      | Some {uidToDecl} -> (
        match Shape.Uid.Tbl.find_opt uidToDecl uid with
        | Some decl -> locOfItemDeclaration decl
        | None -> None)
      | None -> None)
    | _ -> None)
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
  let loc_of_uid = locOfUid ~currentCmtFile:cmtFilePath ~local in
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

(* Identifier occurrences whose definition lives in another compilation unit
   (e.g. [Inst.H.find_opt] where [H] is an instance of a functor constrained by
   a named module type) are reduced through the shapes of the other units, so
   references land on the implementation rather than on the module type item.
   Returns a table from the occurrence's start position to the implementation
   location. *)
let resolveIdentOccurrences ~cmtFilePath (cmt_infos : Cmt_format.cmt_infos) :
    (Lexing.position, Location.t) Hashtbl.t =
  let table = Hashtbl.create 64 in
#if OCAML_VERSION >= (5, 3, 0)
  let module Reduce = Shape_reduce.Make (struct
    let fuel = 10

    let read_unit_shape ~unit_name =
      match loadUnitInfo ~currentCmtFile:cmtFilePath unit_name with
      | Some {shape} -> shape
      | None -> None
  end) in
  let local = cmt_infos.cmt_uid_to_decl in
  let rec uidOfResult (result : Shape_reduce.result) =
    match result with
    | Resolved uid -> Some uid
    | Resolved_alias (_, result) -> uidOfResult result
    | _ -> None
  in
  cmt_infos.cmt_ident_occurrences
  |> List.iter (fun ((lid : Longident.t Location.loc), result) ->
         match result with
         | Shape_reduce.Unresolved shape when not lid.loc.loc_ghost -> (
           match Reduce.reduce_for_uid Env.empty shape |> uidOfResult with
           | Some uid -> (
             match locOfUid ~currentCmtFile:cmtFilePath ~local uid with
             | Some loc when not loc.loc_ghost ->
               Hashtbl.replace table lid.loc.loc_start loc
             | _ -> ())
           | None -> ())
         | _ -> ());
#else
  let _ = (cmtFilePath, cmt_infos) in
#endif
  table
