let concatRelative root fname =
  match Filename.is_relative fname with
  | true -> Filename.concat root fname
  | false -> fname

(** Prepend nativeBuildTarget to fname when provided (-native-build-target) *)
let nativeFilePath fname =
  match !Common.Cli.nativeBuildTarget with
  | None -> fname
  | Some nativeBuildTarget -> concatRelative nativeBuildTarget fname

(* Build systems such as dune record source paths relative to the build root
   (e.g. [src/foo.ml] for [_build/default/src/.lib.objs/byte/foo.cmt]), and
   normalize [cmt_builddir]. The build root is then an ancestor of the .cmt.
   Dune's generated library wrappers ([.ml-gen]) hold only module aliases and
   are not analyzed, as when the analysis runs from the source tree. *)
let ancestorDirs : (string * string, string option) Hashtbl.t = Hashtbl.create 64

let ancestorSourceDir ~cmtFilePath fname =
  let rec search dir =
    if Sys.file_exists (Filename.concat dir fname) then Some dir
    else
      let parent = Filename.dirname dir in
      if parent = dir then None else search parent
  in
  if Filename.check_suffix fname ".ml-gen" then None
  else
    let key = (Filename.dirname cmtFilePath, fname) in
    match Hashtbl.find_opt ancestorDirs key with
    | Some found -> found
    | None ->
      let found = search (fst key) in
      Hashtbl.add ancestorDirs key found;
      found

(* Whether a source path is found, and the directory it is relative to when
   that is not the current one: reports and [-write] read the source there. *)
let sourceDir ?cmtRoot ?cmtFilePath fname =
  (* Found from the current directory, or through [-native-build-target],
     whose reports keep naming the path relative to the current directory. *)
  if Sys.file_exists (nativeFilePath fname) then Some None
  else if not (Filename.is_relative fname) then None
  else
    (* In -dce-cmt mode, source paths in CMT metadata can be relative to the
       scanned build root rather than the current working directory. *)
    match cmtRoot with
    | Some root when Sys.file_exists (concatRelative root fname) ->
      Some (Some root)
    | _ -> (
      match cmtFilePath with
      | Some cmtFilePath ->
        ancestorSourceDir ~cmtFilePath fname |> Option.map Option.some
      | None -> None)

(* Declarations are identified by their source positions. Two build trees
   holding different files under one relative name (e.g. a generated file
   copied from per-platform sources) cannot be told apart: their declarations
   at the same positions are merged. Each copy is compared with the first one
   seen, including the copy in a build tree when the file is also found from
   the current directory, and a difference is reported once per file. *)
let firstCopies : (string, string) Hashtbl.t = Hashtbl.create 256
let comparedCopies : (string, unit) Hashtbl.t = Hashtbl.create 256
let differingSources : (string, unit) Hashtbl.t = Hashtbl.create 4

let checkSameSource fname path =
  match Hashtbl.find_opt firstCopies fname with
  | None -> Hashtbl.add firstCopies fname path
  | Some first
    when first <> path
         && (not (Hashtbl.mem comparedCopies path))
         && not (Hashtbl.mem differingSources fname) ->
    Hashtbl.add comparedCopies path ();
    let digest path = try Some (Digest.file path) with Sys_error _ -> None in
    if digest first <> digest path then (
      Hashtbl.add differingSources fname ();
      Printf.eprintf
        "Warning: %s differs between %s and %s. Declarations at the same \
         positions are merged; give the variants distinct source names (e.g. \
         with dune's copy#).\n\
         %!"
        fname first path)
  | Some _ -> ()

let sourceExists ?cmtRoot ?cmtFilePath fname =
  match sourceDir ?cmtRoot ?cmtFilePath fname with
  | Some (Some dir) ->
    checkSameSource fname (concatRelative dir fname);
    Common.registerSourceDir fname dir;
    true
  | Some None ->
    checkSameSource fname (nativeFilePath fname);
    (match cmtFilePath with
    | Some cmtFilePath when Filename.is_relative fname -> (
      match ancestorSourceDir ~cmtFilePath fname with
      | Some dir -> checkSameSource fname (Filename.concat dir fname)
      | None -> ())
    | _ -> ());
    true
  | None -> false

let rec interface ?cmtRoot ?cmtFilePath items =
  match items with
  | {Typedtree.sig_loc} :: rest -> (
    match sourceExists ?cmtRoot ?cmtFilePath sig_loc.loc_start.pos_fname with
    | false -> interface ?cmtRoot ?cmtFilePath rest
    | true -> Some sig_loc.loc_start.pos_fname)
  | [] -> None

let rec implementation ?cmtRoot ?cmtFilePath items =
  match items with
  | {Typedtree.str_loc} :: rest -> (
    match sourceExists ?cmtRoot ?cmtFilePath str_loc.loc_start.pos_fname with
    | false -> implementation ?cmtRoot ?cmtFilePath rest
    | true -> Some str_loc.loc_start.pos_fname)
  | [] -> None

let sourcefile ?cmtRoot ?cmtFilePath (cmt_infos : Cmt_format.cmt_infos) =
  match cmt_infos.cmt_sourcefile with
  | Some sourceFile when sourceExists ?cmtRoot ?cmtFilePath sourceFile ->
    Some sourceFile
  | _ -> None

let cmt ?cmtRoot ?cmtFilePath (cmt_infos : Cmt_format.cmt_infos) =
  (* Preprocessed/generated locations can point at files that are not present
     locally; cmt_sourcefile usually still names the real source file. *)
  let fallback () = sourcefile ?cmtRoot ?cmtFilePath cmt_infos in
  match cmt_infos.cmt_annots with
  | Cmt_format.Interface signature ->
    if !Common.Cli.debug && signature.sig_items = [] then
      Log_.item "Interface %d@." (signature.sig_items |> List.length);
    (match interface ?cmtRoot ?cmtFilePath signature.sig_items with
    | Some sourceFile -> Some sourceFile
    | None -> fallback ())
  | Implementation structure ->
    if !Common.Cli.debug && structure.str_items = [] then
      Log_.item "Implementation %d@." (structure.str_items |> List.length);
    (match implementation ?cmtRoot ?cmtFilePath structure.str_items with
    | Some sourceFile -> Some sourceFile
    | None -> fallback ())
  | _ -> None
