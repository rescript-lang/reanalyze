let concatRelative root fname =
  match Filename.is_relative fname with
  | true -> Filename.concat root fname
  | false -> fname

(** Prepend nativeBuildTarget to fname when provided (-native-build-target) *)
let nativeFilePath fname =
  match !Common.Cli.nativeBuildTarget with
  | None -> fname
  | Some nativeBuildTarget -> concatRelative nativeBuildTarget fname

let sourceExists ?cmtRoot fname =
  Sys.file_exists (nativeFilePath fname)
  ||
  (* In -dce-cmt mode, source paths in CMT metadata can be relative to the
     scanned build root rather than the current working directory. *)
  match cmtRoot with
  | Some root -> Sys.file_exists (concatRelative root fname)
  | None -> false

let rec interface ?cmtRoot items =
  match items with
  | {Typedtree.sig_loc} :: rest -> (
    match sourceExists ?cmtRoot sig_loc.loc_start.pos_fname with
    | false -> interface ?cmtRoot rest
    | true -> Some sig_loc.loc_start.pos_fname)
  | [] -> None

let rec implementation ?cmtRoot items =
  match items with
  | {Typedtree.str_loc} :: rest -> (
    match sourceExists ?cmtRoot str_loc.loc_start.pos_fname with
    | false -> implementation ?cmtRoot rest
    | true -> Some str_loc.loc_start.pos_fname)
  | [] -> None

let sourcefile ?cmtRoot (cmt_infos : Cmt_format.cmt_infos) =
  match cmt_infos.cmt_sourcefile with
  | Some sourceFile when sourceExists ?cmtRoot sourceFile -> Some sourceFile
  | _ -> None

let cmt ?cmtRoot (cmt_infos : Cmt_format.cmt_infos) =
  (* Preprocessed/generated locations can point at files that are not present
     locally; cmt_sourcefile usually still names the real source file. *)
  let fallback () = sourcefile ?cmtRoot cmt_infos in
  match cmt_infos.cmt_annots with
  | Cmt_format.Interface signature ->
    if !Common.Cli.debug && signature.sig_items = [] then
      Log_.item "Interface %d@." (signature.sig_items |> List.length);
    (match interface ?cmtRoot signature.sig_items with
    | Some sourceFile -> Some sourceFile
    | None -> fallback ())
  | Implementation structure ->
    if !Common.Cli.debug && structure.str_items = [] then
      Log_.item "Implementation %d@." (structure.str_items |> List.length);
    (match implementation ?cmtRoot structure.str_items with
    | Some sourceFile -> Some sourceFile
    | None -> fallback ())
  | _ -> None
