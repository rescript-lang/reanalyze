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
   name. Populated before processing so declaration dependencies pointing at
   other units (e.g. a functor result constrained by a module type defined in
   another file) can be resolved regardless of processing order. *)
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

let extractValueDependencies ~cmtFilePath (cmt_infos : Cmt_format.cmt_infos) =
#if OCAML_VERSION >= (5, 3, 0)
  let module UidTbl = Shape.Uid.Tbl in
  (* The declarations of the file being processed and of its own interface. *)
  let own_uid_to_decl = UidTbl.create 1024 in
  UidTbl.iter (UidTbl.replace own_uid_to_decl) cmt_infos.cmt_uid_to_decl;
  let read_cmt path =
    if Sys.file_exists path then
      try Some (Cmt_format.read_cmt path) with _ -> None
    else None
  in
  (match read_cmt ((cmtFilePath |> Filename.remove_extension) ^ ".cmti") with
  | Some cmti_infos ->
    UidTbl.iter
      (fun uid decl ->
        if not (UidTbl.mem own_uid_to_decl uid) then
          UidTbl.replace own_uid_to_decl uid decl)
      cmti_infos.cmt_uid_to_decl
  | None -> ());
  (* Declarations of other compilation units, one table per candidate file.
     The analysis root can contain several units with the same name (e.g.
     unwrapped libraries in different directories), whose declarations share
     uids. Candidates are narrowed down using the interface digest recorded
     in the importer; when that is not possible every candidate is consulted,
     so a reference is never dropped because the wrong unit was picked. *)
  let loadedFiles : (string, Typedtree.item_declaration UidTbl.t option) Hashtbl.t
      =
    Hashtbl.create 16
  in
  let decls_of_file path =
    match Hashtbl.find_opt loadedFiles path with
    | Some decls -> decls
    | None ->
      let decls =
        match read_cmt path with
        | Some infos -> Some infos.cmt_uid_to_decl
        | None -> None
      in
      Hashtbl.replace loadedFiles path decls;
      decls
  in
  let interface_digest_of_file path =
    match read_cmt path with
    | Some infos -> infos.cmt_interface_digest
    | None -> None
  in
  let loadedUnits : (string, Typedtree.item_declaration UidTbl.t list) Hashtbl.t
      =
    Hashtbl.create 16
  in
  let candidate_files comp_unit =
    let indexed =
      match Hashtbl.find_opt cmtFilesByUnit comp_unit with
      | Some paths -> paths
      | None -> []
    in
    (* Fall back to sibling files, for callers that did not register. *)
    let dir = Filename.dirname cmtFilePath in
    let siblings =
      [".cmt"; ".cmti"]
      |> List.concat_map (fun ext ->
             [
               Filename.concat dir (comp_unit ^ ext);
               Filename.concat dir (String.uncapitalize_ascii comp_unit ^ ext);
             ])
    in
    indexed @ siblings
    |> List.filter (fun path -> path <> cmtFilePath && Sys.file_exists path)
    |> List.sort_uniq compare
  in
  let select_by_digest comp_unit files =
    let digest =
      match List.assoc_opt comp_unit cmt_infos.cmt_imports with
      | Some (Some digest) -> Some digest
      | _ -> None
    in
    match digest with
    | None -> files
    | Some digest -> (
      (* A .cmt compiled against an .mli carries no interface digest: the
         digest is in the .cmti next to it. Group by stem so the whole unit
         is kept when either file matches. *)
      let stem path = Filename.remove_extension path in
      let stems = files |> List.map stem |> List.sort_uniq compare in
      let matching_stems =
        stems
        |> List.filter (fun stem ->
               [".cmt"; ".cmti"]
               |> List.exists (fun ext ->
                      interface_digest_of_file (stem ^ ext) = Some digest))
      in
      match matching_stems with
      | [] -> files
      | _ -> files |> List.filter (fun path -> List.mem (stem path) matching_stems)
      )
  in
  let decls_of_unit comp_unit =
    match Hashtbl.find_opt loadedUnits comp_unit with
    | Some decls -> decls
    | None ->
      let decls =
        candidate_files comp_unit |> select_by_digest comp_unit
        |> List.filter_map decls_of_file
      in
      Hashtbl.replace loadedUnits comp_unit decls;
      decls
  in
  let loc_of_value_decl = function
    | Typedtree.Value {val_loc; _} -> Some val_loc
    | Typedtree.Value_binding {vb_pat = {pat_loc; _}; _} -> Some pat_loc
    | _ -> None
  in
  let locs_of_uid uid =
    match UidTbl.find_opt own_uid_to_decl uid with
    | Some item_decl -> Option.to_list (loc_of_value_decl item_decl)
    | None -> (
      match uid with
      | Shape.Uid.Item {comp_unit; _} ->
        decls_of_unit comp_unit
        |> List.filter_map (fun decls ->
               match UidTbl.find_opt decls uid with
               | Some item_decl -> loc_of_value_decl item_decl
               | None -> None)
        |> List.sort_uniq compare
      | _ -> [])
  in
  cmt_infos.cmt_declaration_dependencies
  |> List.concat_map (fun (_, uid_def, uid_decl) ->
         let decl_locs = locs_of_uid uid_decl in
         locs_of_uid uid_def
         |> List.concat_map (fun def_loc ->
                decl_locs |> List.map (fun decl_loc -> (def_loc, decl_loc))))
#else
  let _ = cmtFilePath in
  cmt_infos.cmt_value_dependencies
  |> List.map (fun (valueTo, valueFrom) ->
         (valueTo.Types.val_loc, valueFrom.Types.val_loc))
#endif
