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
   normalize [cmt_builddir]. The build root is then an ancestor of the .cmt,
   as is the root scanned by [-dce-cmt]. Dune's generated library wrappers
   ([.ml-gen]) hold only module aliases and are not analyzed, as when the
   analysis runs from the source tree. *)
let ancestorDirs : (string * string, string option) Hashtbl.t = Hashtbl.create 64

let ancestorSourceDir ~cmtFilePath fname =
  let rec search dir =
    if Sys.file_exists (Filename.concat dir fname) then Some dir
    else
      let parent = Filename.dirname dir in
      if parent = dir then None else search parent
  in
  if Filename.check_suffix fname ".ml-gen" || not (Filename.is_relative fname)
  then None
  else
    let key = (Filename.dirname cmtFilePath, fname) in
    match Hashtbl.find_opt ancestorDirs key with
    | Some found -> found
    | None ->
      let found = search (fst key) in
      Hashtbl.add ancestorDirs key found;
      found

(* Declarations are identified by their source positions. Two build trees
   holding different files under one relative name (e.g. a generated file
   copied from per-platform sources) cannot be told apart: their declarations
   at the same positions are merged. Each copy is compared with the first one
   seen, including the copy in a build tree when the file is also found from
   the current directory, and a difference is reported once per file. *)
let firstCopies : (string, string) Hashtbl.t = Hashtbl.create 256
let comparedCopies : (string, unit) Hashtbl.t = Hashtbl.create 256
let currentCopies : (string, unit) Hashtbl.t = Hashtbl.create 256
let differingSources : (string, unit) Hashtbl.t = Hashtbl.create 4

let checkSameSource ?(current = false) fname path =
  if current then Hashtbl.replace currentCopies path ();
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
      if current || Hashtbl.mem currentCopies first then
        (* Usually a source edited since the last build. *)
        Printf.eprintf
          "Warning: %s differs between %s and %s. The build is out of date; \
           rebuild before analyzing.\n\
           %!"
          fname first path
      else
        Printf.eprintf
          "Warning: %s differs between %s and %s. Declarations at the same \
           positions are merged; give the variants distinct source names \
           (e.g. with dune's copy#).\n\
           %!"
          fname first path)
  | Some _ -> ()

(* Whether a source path is found: from the current directory (or through
   [-native-build-target], whose reports keep naming the path relative to the
   current directory), or else in an ancestor of the .cmt, from where reports
   and [-write] then read it. *)
let sourceExists ~cmtFilePath fname =
  let ancestor = ancestorSourceDir ~cmtFilePath fname in
  if Sys.file_exists (nativeFilePath fname) then (
    checkSameSource ~current:true fname (nativeFilePath fname);
    ancestor
    |> Option.iter (fun dir ->
           checkSameSource fname (Filename.concat dir fname));
    true)
  else
    match ancestor with
    | Some dir ->
      checkSameSource fname (Filename.concat dir fname);
      Common.registerSourceDir fname dir;
      true
    | None -> false

(* The source of the first item whose location names an existing file. *)
let firstSource ~cmtFilePath locs =
  locs
  |> List.find_map (fun (loc : Location.t) ->
         let fname = loc.loc_start.pos_fname in
         if sourceExists ~cmtFilePath fname then Some fname else None)

let interface ~cmtFilePath items =
  items
  |> List.map (fun (item : Typedtree.signature_item) -> item.sig_loc)
  |> firstSource ~cmtFilePath

let implementation ~cmtFilePath items =
  items
  |> List.map (fun (item : Typedtree.structure_item) -> item.str_loc)
  |> firstSource ~cmtFilePath

let sourcefile ~cmtFilePath (cmt_infos : Cmt_format.cmt_infos) =
  match cmt_infos.cmt_sourcefile with
  | Some sourceFile when sourceExists ~cmtFilePath sourceFile -> Some sourceFile
  | _ -> None

let cmt ~cmtFilePath (cmt_infos : Cmt_format.cmt_infos) =
  (* Preprocessed/generated locations can point at files that are not present
     locally; cmt_sourcefile usually still names the real source file. *)
  let fallback () = sourcefile ~cmtFilePath cmt_infos in
  match cmt_infos.cmt_annots with
  | Cmt_format.Interface signature ->
    if !Common.Cli.debug && signature.sig_items = [] then
      Log_.item "Interface %d@." (signature.sig_items |> List.length);
    (match interface ~cmtFilePath signature.sig_items with
    | Some sourceFile -> Some sourceFile
    | None -> fallback ())
  | Implementation structure ->
    if !Common.Cli.debug && structure.str_items = [] then
      Log_.item "Implementation %d@." (structure.str_items |> List.length);
    (match implementation ~cmtFilePath structure.str_items with
    | Some sourceFile -> Some sourceFile
    | None -> fallback ())
  | _ -> None
